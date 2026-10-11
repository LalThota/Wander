"""Wander API: destinations, travel options, tourist places, budgets, saved trips.

Run:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
Docs: http://localhost:8000/docs
"""
import json
import os
import sqlite3
import time
from contextlib import asynccontextmanager, contextmanager
from typing import Annotated, Literal, Optional

from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

from providers import (
    BUDGET_KEYS, CATEGORIES, DEST_BY_ID, build_travel_plan, budget_status,
    get_places_provider, pack_for, sort_places, suggest_split,
)
from seed import DESTINATIONS
from seed_places import GEO

MOODS = {"beach", "mountain", "culture"}
MAX_MONEY = 10_000_000

SCHEMA = """
CREATE TABLE IF NOT EXISTS destinations (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, country TEXT NOT NULL,
    tagline TEXT NOT NULL, season TEXT NOT NULL, flight_time TEXT NOT NULL,
    temp INTEGER NOT NULL, per_day INTEGER NOT NULL, flight INTEGER NOT NULL,
    mood TEXT NOT NULL, peaks INTEGER NOT NULL,
    sky_top TEXT NOT NULL, sky_bottom TEXT NOT NULL, sun TEXT NOT NULL,
    layers TEXT NOT NULL, pack TEXT NOT NULL, sort_order INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS trips (
    client_id TEXT NOT NULL, destination_id TEXT NOT NULL,
    days INTEGER NOT NULL, packed TEXT NOT NULL, total INTEGER NOT NULL,
    updated_at REAL NOT NULL,
    PRIMARY KEY (client_id, destination_id)
);
"""

# Columns added after v1. Added in place, existing rows keep their data and get
# these defaults, so old saved trips keep opening.
TRIP_MIGRATIONS = {
    "budget": "INTEGER",
    "breakdown": "TEXT NOT NULL DEFAULT '{}'",
    "travel_mode": "TEXT",
    "travel_cost": "INTEGER",
    "travelers": "INTEGER NOT NULL DEFAULT 1",
    "places": "TEXT NOT NULL DEFAULT '[]'",
}


def db_path() -> str:
    default = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wander.db")
    return os.environ.get("WANDER_DB", default)


@contextmanager
def db():
    conn = sqlite3.connect(db_path())
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def migrate(conn: sqlite3.Connection) -> None:
    have = {r["name"] for r in conn.execute("PRAGMA table_info(trips)")}
    for col, ddl in TRIP_MIGRATIONS.items():
        if col not in have:
            conn.execute(f"ALTER TABLE trips ADD COLUMN {col} {ddl}")


def init_db() -> None:
    with db() as conn:
        conn.executescript(SCHEMA)
        migrate(conn)
        for order, d in enumerate(DESTINATIONS):
            conn.execute(
                """INSERT OR REPLACE INTO destinations
                   (id, name, country, tagline, season, flight_time, temp, per_day,
                    flight, mood, peaks, sky_top, sky_bottom, sun, layers, pack, sort_order)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (d["id"], d["name"], d["country"], d["tagline"], d["season"],
                 d["flight_time"], d["temp"], d["per_day"], d["flight"], d["mood"],
                 int(d["peaks"]), d["sky_top"], d["sky_bottom"], d["sun"],
                 json.dumps(d["layers"]), json.dumps(pack_for(d)), order),
            )


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title="Wander API", version="2.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

ClientId = Annotated[
    str, Query(min_length=8, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
]


# ───────────── models ─────────────

def _check_breakdown(b: dict[str, int]) -> dict[str, int]:
    for k, v in b.items():
        if k not in BUDGET_KEYS:
            raise ValueError(f"unknown budget category '{k}'")
        if v < 0 or v > MAX_MONEY:
            raise ValueError(f"'{k}' must be between 0 and {MAX_MONEY}")
    return {k: v for k, v in b.items() if v > 0}


class PlaceRef(BaseModel):
    id: str = Field(min_length=1, max_length=80)
    name: str = Field(min_length=1, max_length=120)


class TripIn(BaseModel):
    client_id: str = Field(min_length=8, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
    destination_id: str = Field(min_length=1, max_length=64)
    days: int = Field(ge=1, le=60)
    packed: list[str] = Field(default_factory=list, max_length=50)  # required items checklist
    # added in v2, all optional so older clients keep working
    budget: Optional[int] = Field(default=None, ge=0, le=MAX_MONEY)
    breakdown: dict[str, int] = Field(default_factory=dict)
    travel_mode: Optional[Literal["train", "flight", "bus", "car"]] = None
    travelers: int = Field(default=1, ge=1, le=20)
    places: list[PlaceRef] = Field(default_factory=list, max_length=30)

    @field_validator("breakdown")
    @classmethod
    def _breakdown_ok(cls, v):
        return _check_breakdown(v)


class BudgetIn(BaseModel):
    total_budget: int = Field(ge=0, le=MAX_MONEY)
    breakdown: dict[str, int] = Field(default_factory=dict)

    @field_validator("breakdown")
    @classmethod
    def _breakdown_ok(cls, v):
        return _check_breakdown(v)


def destination_out(r: sqlite3.Row) -> dict:
    geo = GEO.get(r["id"], {})
    return {
        "id": r["id"], "name": r["name"], "country": r["country"],
        "tagline": r["tagline"], "season": r["season"],
        "flight_time": r["flight_time"], "temp": r["temp"],
        "per_day": r["per_day"], "flight": r["flight"], "mood": r["mood"],
        "peaks": bool(r["peaks"]), "sky_top": r["sky_top"],
        "sky_bottom": r["sky_bottom"], "sun": r["sun"],
        "layers": json.loads(r["layers"]), "pack": json.loads(r["pack"]),
        "rating": DEST_BY_ID.get(r["id"], {}).get("rating", 4.5),
        "lat": geo.get("lat"),
        "lng": geo.get("lng"),
    }


def trip_out(r: sqlite3.Row) -> dict:
    return {
        "destination_id": r["destination_id"], "days": r["days"],
        "packed": json.loads(r["packed"]), "total": r["total"],
        "updated_at": r["updated_at"],
        # v2 fields. budget stays null for trips saved before budgets existed.
        "budget": r["budget"],
        "breakdown": json.loads(r["breakdown"] or "{}"),
        "travel_mode": r["travel_mode"],
        "travel_cost": r["travel_cost"],
        "travelers": r["travelers"] or 1,
        "places": json.loads(r["places"] or "[]"),
    }


def get_destination(conn: sqlite3.Connection, dest_id: str) -> sqlite3.Row:
    row = conn.execute("SELECT * FROM destinations WHERE id = ?", (dest_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Destination not found")
    return row


def require_destination(dest_id: str) -> None:
    if dest_id not in DEST_BY_ID:
        raise HTTPException(status_code=404, detail="Destination not found")


# ───────────── destinations ─────────────

@app.get("/api/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/api/destinations")
def list_destinations(
    mood: Optional[str] = None, q: Optional[str] = Query(default=None, max_length=80)
) -> list[dict]:
    if mood is not None and mood not in MOODS:
        raise HTTPException(status_code=422, detail=f"mood must be one of {sorted(MOODS)}")
    sql, params = "SELECT * FROM destinations WHERE 1=1", []
    if mood:
        sql += " AND mood = ?"
        params.append(mood)
    if q and q.strip():
        sql += " AND lower(name || ' ' || country || ' ' || tagline) LIKE ?"
        params.append(f"%{q.strip().lower()}%")
    sql += " ORDER BY sort_order"
    with db() as conn:
        return [destination_out(r) for r in conn.execute(sql, params).fetchall()]


@app.get("/api/destinations/{dest_id}")
def one_destination(dest_id: str) -> dict:
    with db() as conn:
        return destination_out(get_destination(conn, dest_id))


@app.get("/api/destinations/{dest_id}/estimate")
def estimate(dest_id: str, days: int = Query(ge=1, le=60)) -> dict:
    with db() as conn:
        d = get_destination(conn, dest_id)
    return {
        "days": days, "per_day": d["per_day"], "flight": d["flight"],
        "total": days * d["per_day"] + d["flight"],
    }


# ───────────── travel options, places, budget ─────────────

@app.get("/api/destinations/{dest_id}/travel")
def travel_options(dest_id: str, travelers: int = Query(default=1, ge=1, le=20)) -> dict:
    """Estimated (not live) travel options with cheapest/fastest/value picks."""
    require_destination(dest_id)
    return build_travel_plan(dest_id, travelers)


@app.get("/api/destinations/{dest_id}/places")
def tourist_places(
    dest_id: str,
    category: Optional[str] = None,
    sort: Literal["nearest", "popular", "category"] = "nearest",
) -> list[dict]:
    """Nearby tourist places. Distances are straight-line from the centre."""
    require_destination(dest_id)
    if category is not None and category not in CATEGORIES:
        raise HTTPException(status_code=422, detail=f"category must be one of {CATEGORIES}")
    places = get_places_provider().nearby(dest_id)
    if category:
        places = [p for p in places if p["category"] == category]
    return sort_places(places, sort)


@app.get("/api/destinations/{dest_id}/budget/suggest")
def budget_suggestion(dest_id: str, total: int = Query(ge=1, le=MAX_MONEY)) -> dict:
    """A starting split for a total budget. Only a suggestion, users can edit it."""
    require_destination(dest_id)
    return suggest_split(dest_id, total)


@app.post("/api/budget/validate")
def validate_budget(body: BudgetIn) -> dict:
    return budget_status(body.total_budget, body.breakdown)


# ───────────── saved trips ─────────────

@app.get("/api/trips")
def list_trips(client_id: ClientId) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM trips WHERE client_id = ? ORDER BY updated_at DESC",
            (client_id,),
        ).fetchall()
    return [trip_out(r) for r in rows]


@app.put("/api/trips")
def save_trip(body: TripIn) -> dict:
    allocated = sum(body.breakdown.values())
    if allocated > (body.budget or 0):
        raise HTTPException(
            status_code=422,
            detail="Budget split is higher than the total budget"
            if body.budget else "Set a total budget before splitting it",
        )

    with db() as conn:
        d = get_destination(conn, body.destination_id)
        allowed = json.loads(d["pack"])
        # keep only real checklist items, no duplicates, original order
        packed = [i for i in allowed if i in set(body.packed)]
        total = body.days * d["per_day"] + d["flight"]

        travel_cost = None
        if body.travel_mode:
            plan = build_travel_plan(body.destination_id, body.travelers)
            match = next((o for o in plan["options"] if o["mode"] == body.travel_mode), None)
            if match is None:
                raise HTTPException(
                    status_code=422,
                    detail=f"{body.travel_mode} is not available for this destination",
                )
            travel_cost = match["cost_total"]  # computed here, never trusted from the client

        conn.execute(
            """INSERT INTO trips (client_id, destination_id, days, packed, total, updated_at,
                                  budget, breakdown, travel_mode, travel_cost, travelers, places)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
               ON CONFLICT(client_id, destination_id) DO UPDATE SET
                 days=excluded.days, packed=excluded.packed, total=excluded.total,
                 updated_at=excluded.updated_at, budget=excluded.budget,
                 breakdown=excluded.breakdown, travel_mode=excluded.travel_mode,
                 travel_cost=excluded.travel_cost, travelers=excluded.travelers,
                 places=excluded.places""",
            (body.client_id, body.destination_id, body.days, json.dumps(packed),
             total, time.time(), body.budget or None, json.dumps(body.breakdown),
             body.travel_mode, travel_cost, body.travelers,
             json.dumps([p.model_dump() for p in body.places])),
        )
        row = conn.execute(
            "SELECT * FROM trips WHERE client_id = ? AND destination_id = ?",
            (body.client_id, body.destination_id),
        ).fetchone()
    return trip_out(row)


@app.delete("/api/trips/{destination_id}", status_code=204)
def delete_trip(destination_id: str, client_id: ClientId) -> Response:
    with db() as conn:
        conn.execute(
            "DELETE FROM trips WHERE client_id = ? AND destination_id = ?",
            (client_id, destination_id),
        )
    return Response(status_code=204)


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)

