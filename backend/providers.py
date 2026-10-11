"""Pluggable data sources for travel options and tourist places, plus budget helpers.

Today both providers use built-in estimates / seed data. To go live later,
write a class with the same method and return it from get_*_provider().
The Flutter app only sees the JSON shape, so it needs no changes.
"""
import math
import os
import re
from typing import Protocol

from seed import DESTINATIONS
from seed_places import GEO, PLACES

DEST_BY_ID = {d["id"]: d for d in DESTINATIONS}

CATEGORIES = ["Beaches", "Historical", "Nature", "Adventure", "Religious",
              "Shopping", "Food", "Entertainment"]
BUDGET_KEYS = ["travel", "stay", "food", "transport", "activities", "other"]
MODES = ("train", "flight", "bus", "car")

# Value of one hour of travel time in rupees, used for the "best value" pick.
HOUR_VALUE = 150

UNIVERSAL_PACK = ["ID proof", "Phone charger", "Power bank", "Medicines",
                  "Comfortable shoes"]


def pack_for(dest: dict) -> list[str]:
    """Checklist items: essentials first, then destination-specific ones."""
    pack = list(UNIVERSAL_PACK)
    seen = {i.lower() for i in pack}
    items = dest["pack"]
    overseas = GEO[dest["id"]]["road_km"] is None
    if overseas and not any("adapter" in i.lower() for i in items):
        pack.append("Travel adapter")
        seen.add("travel adapter")
    for i in items:
        if i.lower() not in seen:
            pack.append(i)
            seen.add(i.lower())
    return pack


# ───────────── tourist places ─────────────

def haversine_km(lat1, lng1, lat2, lng2) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def map_url(lat: float, lng: float) -> str:
    # Google Maps URL scheme: opens the Maps app or website, no API key needed.
    return f"https://www.google.com/maps/search/?api=1&query={lat},{lng}"


class PlacesProvider(Protocol):
    def nearby(self, dest_id: str) -> list[dict]: ...


class SeedPlacesProvider:
    def nearby(self, dest_id: str) -> list[dict]:
        geo = GEO[dest_id]
        out = []
        for p in PLACES.get(dest_id, []):
            out.append({
                **p,
                "distance_km": round(haversine_km(geo["lat"], geo["lng"], p["lat"], p["lng"]), 1),
                "map_url": map_url(p["lat"], p["lng"]),
            })
        return out


def get_places_provider() -> PlacesProvider:
    # PLACES_PROVIDER=seed is the only built-in. Add e.g. "google" here later,
    # reading its key from the environment (never from source code).
    return SeedPlacesProvider()


def sort_places(places: list[dict], sort: str) -> list[dict]:
    if sort == "popular":
        return sorted(places, key=lambda p: (-p["popularity"], p["distance_km"]))
    if sort == "category":
        return sorted(places, key=lambda p: (p["category"], p["distance_km"]))
    return sorted(places, key=lambda p: p["distance_km"])


# ───────────── travel options ─────────────

def _hours(flight_time: str) -> float:
    m = re.match(r"\s*(\d+)h\s*(\d+)m", flight_time)
    return int(m.group(1)) + int(m.group(2)) / 60 if m else 0.0


def _round(v: float, unit: int = 50) -> int:
    return int(round(v / unit) * unit)


class TravelProvider(Protocol):
    def options(self, dest_id: str, travelers: int) -> list[dict]: ...


class EstimateTravelProvider:
    """Rule-of-thumb round-trip estimates. NOT live fares."""

    def options(self, dest_id: str, travelers: int) -> list[dict]:
        d, geo = DEST_BY_ID[dest_id], GEO[dest_id]
        km = geo["road_km"]
        out = []
        for mode in geo["modes"]:
            if mode == "flight":
                per = d["flight"]
                total = per * travelers
                hours = _hours(d["flight_time"])
                desc = "Fastest option, best for long distances. Return fare."
                suited = "Long distances and short trips"
            elif mode == "train" and km:
                per = _round(1.8 * km)
                total = per * travelers
                hours = km / 55
                desc = "Comfortable and budget friendly. Book early for popular routes."
                suited = "Solo travellers and families"
            elif mode == "bus" and km:
                per = _round(2.2 * km)
                total = per * travelers
                hours = km / 50
                desc = "Flexible and cheap, but longer and less comfortable."
                suited = "Tight budgets"
            elif mode == "car" and km:
                vehicles = math.ceil(travelers / 5)
                total = _round(8 * km) * vehicles
                per = math.ceil(total / travelers)
                hours = km / 60
                desc = "Door to door freedom. Fuel and tolls are shared by everyone in the car."
                suited = "Groups and families"
            else:
                continue
            out.append({
                "mode": mode, "cost_per_person": int(per), "cost_total": int(total),
                "hours": round(hours, 1), "description": desc,
                "suitable_for": suited, "estimated": True, "source": "estimate",
            })
        return out


def get_travel_provider() -> TravelProvider:
    return EstimateTravelProvider()


def build_travel_plan(dest_id: str, travelers: int, provider: TravelProvider | None = None) -> dict:
    provider = provider or get_travel_provider()
    options = provider.options(dest_id, travelers)
    if not options:
        return {"options": [], "recommendations": {}, "group_size": travelers,
                "estimated": True, "note": "No travel estimates for this destination yet."}
    group_n = max(travelers, 4)
    group_opts = provider.options(dest_id, group_n)

    def pick(opts, key):
        return min(opts, key=key)["mode"]

    return {
        "options": options,
        "recommendations": {
            "cheapest": pick(options, lambda o: o["cost_per_person"]),
            "fastest": pick(options, lambda o: o["hours"]),
            "best_value": pick(options, lambda o: o["cost_per_person"] + o["hours"] * HOUR_VALUE),
            "best_group": pick(group_opts, lambda o: o["cost_per_person"]),
        },
        "group_size": group_n,
        "estimated": True,
        "note": ("Estimates from typical return fares, not live or bookable prices. "
                 "Assumes you start from a major Indian city."),
    }


# ───────────── budget ─────────────

DOMESTIC_SPLIT = {"travel": 25, "stay": 25, "food": 20, "transport": 10, "activities": 15, "other": 5}
OVERSEAS_SPLIT = {"travel": 35, "stay": 25, "food": 15, "transport": 5, "activities": 15, "other": 5}


def suggest_split(dest_id: str, total: int) -> dict:
    overseas = GEO[dest_id]["road_km"] is None
    pct = OVERSEAS_SPLIT if overseas else DOMESTIC_SPLIT
    unit = 100 if total >= 5000 else 10
    amounts = {k: (total * pct[k] // 100) // unit * unit for k in BUDGET_KEYS if k != "other"}
    amounts["other"] = total - sum(amounts.values())  # absorbs rounding, sums exactly
    return {"total": total, "percentages": pct, "breakdown": {k: amounts[k] for k in BUDGET_KEYS}}


def budget_status(total: int, breakdown: dict) -> dict:
    allocated = sum(breakdown.values())
    remaining = total - allocated
    if allocated > total:
        state = "over"
    elif allocated == total and total > 0:
        state = "full"
    else:
        state = "under"
    return {"total": total, "allocated": allocated, "remaining": max(remaining, 0),
            "over_by": max(-remaining, 0), "state": state}
