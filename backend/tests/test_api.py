import os
import sys
import tempfile

os.environ["WANDER_DB"] = os.path.join(tempfile.mkdtemp(), "test.db")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient

from main import app

CID = "abcdef1234567890"


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def test_health(client):
    assert client.get("/api/health").json() == {"status": "ok"}


def test_list_and_filter(client):
    all_ = client.get("/api/destinations").json()
    assert len(all_) == 8
    assert isinstance(all_[0]["peaks"], bool)
    assert all_[0]["layers"][0].startswith("#")
    beach = client.get("/api/destinations", params={"mood": "beach"}).json()
    assert {d["mood"] for d in beach} == {"beach"}
    found = client.get("/api/destinations", params={"q": "kyoto"}).json()
    assert [d["id"] for d in found] == ["kyoto"]
    assert client.get("/api/destinations", params={"mood": "space"}).status_code == 422


def test_detail_and_estimate(client):
    assert client.get("/api/destinations/bali").json()["name"] == "Bali"
    assert client.get("/api/destinations/nope").status_code == 404
    est = client.get("/api/destinations/bali/estimate", params={"days": 5}).json()
    assert est["total"] == 5 * 6500 + 28000
    assert client.get("/api/destinations/bali/estimate", params={"days": 0}).status_code == 422


def test_trip_lifecycle(client):
    assert client.get("/api/trips", params={"client_id": CID}).json() == []
    body = {"client_id": CID, "destination_id": "bali", "days": 7,
            "packed": ["Sarong", "Sunscreen", "Not a real item", "Sarong"]}
    saved = client.put("/api/trips", json=body).json()
    assert saved["total"] == 7 * 6500 + 28000
    assert saved["packed"] == ["Sunscreen", "Sarong"]

    body["days"] = 3
    updated = client.put("/api/trips", json=body).json()
    assert updated["days"] == 3
    trips = client.get("/api/trips", params={"client_id": CID}).json()
    assert len(trips) == 1

    # another device never sees this trip
    assert client.get("/api/trips", params={"client_id": "zzzzzzzz9999"}).json() == []

    assert client.delete("/api/trips/bali", params={"client_id": CID}).status_code == 204
    assert client.get("/api/trips", params={"client_id": CID}).json() == []


def test_validation(client):
    bad = {"client_id": "short", "destination_id": "bali", "days": 3, "packed": []}
    assert client.put("/api/trips", json=bad).status_code == 422
    ghost = {"client_id": CID, "destination_id": "atlantis", "days": 3, "packed": []}
    assert client.put("/api/trips", json=ghost).status_code == 404
    toolong = {"client_id": CID, "destination_id": "bali", "days": 999, "packed": []}
    assert client.put("/api/trips", json=toolong).status_code == 422


# ───────────── v2: budget, travel, places, migration ─────────────

def test_budget_suggest_and_validate(client):
    s = client.get("/api/destinations/jaipur/budget/suggest", params={"total": 30000}).json()
    assert sum(s["breakdown"].values()) == 30000
    assert set(s["breakdown"]) == {"travel", "stay", "food", "transport", "activities", "other"}
    assert s["percentages"]["travel"] == 25
    odd = client.get("/api/destinations/bali/budget/suggest", params={"total": 12345}).json()
    assert sum(odd["breakdown"].values()) == 12345
    assert all(v >= 0 for v in odd["breakdown"].values())
    assert client.get("/api/destinations/nope/budget/suggest", params={"total": 100}).status_code == 404
    assert client.get("/api/destinations/bali/budget/suggest", params={"total": 0}).status_code == 422

    def check(total, parts):
        return client.post("/api/budget/validate", json={"total_budget": total, "breakdown": parts}).json()
    assert check(30000, {"travel": 25000})["state"] == "under"
    assert check(30000, {"travel": 25000})["remaining"] == 5000
    assert check(30000, {"travel": 30000})["state"] == "full"
    over = check(30000, {"travel": 34000})
    assert over["state"] == "over" and over["over_by"] == 4000 and over["remaining"] == 0
    bad = client.post("/api/budget/validate", json={"total_budget": 100, "breakdown": {"yacht": 5}})
    assert bad.status_code == 422
    neg = client.post("/api/budget/validate", json={"total_budget": 100, "breakdown": {"food": -5}})
    assert neg.status_code == 422


def test_travel_options(client):
    plan = client.get("/api/destinations/jaipur/travel").json()
    assert {o["mode"] for o in plan["options"]} == {"train", "flight", "bus", "car"}
    assert all(o["estimated"] for o in plan["options"])
    assert "not live" in plan["note"].lower()
    recs = plan["recommendations"]
    assert recs["fastest"] == "flight" and recs["cheapest"] in {"train", "bus"}

    ladakh = client.get("/api/destinations/ladakh/travel").json()
    assert "train" not in {o["mode"] for o in ladakh["options"]}

    bali = client.get("/api/destinations/bali/travel").json()
    assert [o["mode"] for o in bali["options"]] == ["flight"]

    # a car is shared, so per-person cost drops as the group grows
    one = next(o for o in client.get("/api/destinations/jaipur/travel", params={"travelers": 1}).json()["options"] if o["mode"] == "car")
    four = next(o for o in client.get("/api/destinations/jaipur/travel", params={"travelers": 4}).json()["options"] if o["mode"] == "car")
    assert four["cost_per_person"] < one["cost_per_person"]
    assert four["cost_total"] == one["cost_total"]

    assert client.get("/api/destinations/nope/travel").status_code == 404
    assert client.get("/api/destinations/jaipur/travel", params={"travelers": 0}).status_code == 422


def test_places(client):
    places = client.get("/api/destinations/bali/places").json()
    assert len(places) == 5
    dists = [p["distance_km"] for p in places]
    assert dists == sorted(dists)                      # nearest first by default
    assert places[0]["map_url"].startswith("https://www.google.com/maps/")
    assert "key=" not in places[0]["map_url"]          # no API key in URLs
    popular = client.get("/api/destinations/bali/places", params={"sort": "popular"}).json()
    assert popular[0]["popularity"] == max(p["popularity"] for p in places)
    nature = client.get("/api/destinations/bali/places", params={"category": "Nature"}).json()
    assert nature and {p["category"] for p in nature} == {"Nature"}
    assert client.get("/api/destinations/bali/places", params={"category": "Spaceports"}).status_code == 422
    assert client.get("/api/destinations/bali/places", params={"sort": "loudest"}).status_code == 422
    assert client.get("/api/destinations/nope/places").status_code == 404


def test_destinations_have_ratings(client):
    ds = client.get("/api/destinations").json()
    assert all(4.0 <= d["rating"] <= 5.0 for d in ds)


def test_checklist_includes_essentials(client):
    pack = client.get("/api/destinations/santorini").json()["pack"]
    assert pack[:2] == ["ID proof", "Phone charger"] and "Power adapter" in pack


def test_trip_v2_roundtrip(client):
    body = {
        "client_id": CID, "destination_id": "jaipur", "days": 4, "packed": ["Power bank", "ID proof"],
        "budget": 30000,
        "breakdown": {"travel": 8000, "stay": 7000, "food": 5000, "transport": 3000, "activities": 4000, "other": 3000},
        "travel_mode": "train", "travelers": 2,
        "places": [{"id": "amber-fort", "name": "Amber Fort"}],
    }
    t = client.put("/api/trips", json=body).json()
    assert t["budget"] == 30000 and t["travel_mode"] == "train"
    assert t["travel_cost"] == 2 * 1100                # computed by the server
    assert t["packed"] == ["ID proof", "Power bank"]
    assert t["places"] == [{"id": "amber-fort", "name": "Amber Fort"}]
    assert t["breakdown"]["travel"] == 8000

    body["travel_cost"] = 1                              # client-supplied cost is ignored
    assert client.put("/api/trips", json=body).json()["travel_cost"] == 2200

    over = {**body, "breakdown": {"travel": 31000}}
    assert client.put("/api/trips", json=over).status_code == 422
    no_budget = {**body, "budget": None}
    assert client.put("/api/trips", json=no_budget).status_code == 422
    bad_mode = {**body, "destination_id": "bali", "travel_mode": "train", "breakdown": {}}
    assert client.put("/api/trips", json=bad_mode).status_code == 422
    unknown_cat = {**body, "breakdown": {"yacht": 10}}
    assert client.put("/api/trips", json=unknown_cat).status_code == 422
    client.delete("/api/trips/jaipur", params={"client_id": CID})


def test_v1_style_request_still_works(client):
    """An older app that only sends the original fields keeps working."""
    body = {"client_id": CID, "destination_id": "kyoto", "days": 3, "packed": ["Cash"]}
    t = client.put("/api/trips", json=body).json()
    assert t["budget"] is None and t["breakdown"] == {} and t["travel_mode"] is None
    assert t["places"] == [] and t["travelers"] == 1
    client.delete("/api/trips/kyoto", params={"client_id": CID})


def test_old_database_is_migrated_without_data_loss(tmp_path, monkeypatch):
    import sqlite3 as sq
    import main as m
    old = tmp_path / "old.db"
    conn = sq.connect(old)
    conn.executescript(
        """CREATE TABLE trips (client_id TEXT NOT NULL, destination_id TEXT NOT NULL,
             days INTEGER NOT NULL, packed TEXT NOT NULL, total INTEGER NOT NULL,
             updated_at REAL NOT NULL, PRIMARY KEY (client_id, destination_id));
           INSERT INTO trips VALUES ('legacyclient1', 'bali', 5, '["Sarong"]', 60500, 1.0);"""
    )
    conn.commit(); conn.close()
    monkeypatch.setenv("WANDER_DB", str(old))
    with TestClient(m.app) as c:
        trips = c.get("/api/trips", params={"client_id": "legacyclient1"}).json()
        assert len(trips) == 1
        t = trips[0]
        assert t["days"] == 5 and t["packed"] == ["Sarong"] and t["total"] == 60500
        assert t["budget"] is None and t["breakdown"] == {} and t["places"] == []
        # and it can be edited in the new format afterwards
        upd = {"client_id": "legacyclient1", "destination_id": "bali", "days": 6,
               "packed": ["Sarong"], "budget": 80000, "breakdown": {"stay": 20000}}
        assert c.put("/api/trips", json=upd).json()["budget"] == 80000
