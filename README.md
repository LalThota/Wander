# Wander

Travel destination app. Flutter front end (phone, tablet, web, desktop) and a FastAPI + SQLite back end.

```
wander/
  backend/   FastAPI API, SQLite DB, tests (pytest)
  app/       Flutter app
```

## 1. Run the API locally

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
pytest            # 13 tests
```

Docs: http://localhost:8000/docs

**Existing database:** nothing to do. On start the API adds the new trip columns in place
(`ALTER TABLE ... ADD COLUMN` with defaults), so trips saved earlier keep opening. No data is deleted.

## 2. Run the app

```bash
cd app
flutter create . --project-name wander --org com.example   # first time only, adds android/ios/web...
flutter pub get
flutter run -d chrome
```

Delete the generated `test/widget_test.dart` (it points at a demo app). `test/wander_test.dart` replaces it.

### Which server does the app talk to?

| Build | Default |
|---|---|
| `flutter run` (debug) | `http://localhost:8000` (Android emulator: `http://10.0.2.2:8000`) |
| `flutter build ...` (release) | `https://wander-app-xp36.onrender.com` |
| anything, any mode | `--dart-define=API_URL=https://your-server` wins |

To try the deployed server while developing: `flutter run --dart-define=API_URL=https://wander-app-xp36.onrender.com`.
The free Render tier sleeps, so the first request can take up to a minute. The app waits 45 s and says so.

Android needs, in `android/app/src/main/AndroidManifest.xml`, above `<application`:
`<uses-permission android:name="android.permission.INTERNET"/>`, and while using plain `http://` in
development add `android:usesCleartextTraffic="true"` to the `<application` tag.

### App icon
```bash
dart run flutter_launcher_icons
```
Uses `assets/icon/icon.png` and `icon_fg.png`, the same mark as the opening animation.

### Real photos
The pictures are drawn in code so the app works with no files. To use real photos, put them in
`app/assets/images/` (see the README.txt there): `bali.jpg`, `bali_1.jpg` ... `welcome.jpg`.
They replace the drawings automatically. Use photos you own or are licensed to use.

## What is in v2
- Opening animation (logo), first-run welcome screen, then the app.
- Home, Saved trips, Explore (View all), Profile, with a floating bottom bar.
- Destination page, top to bottom: header, total budget, budget breakdown, travel comparison,
  required items, nearby places, save.
- Budget split with remaining/over-budget states, suggested split, per-category editing.
- Travel comparison (train, flight, bus, car): cost, time, cheapest/fastest/best value/group pick.
  **Estimates only, never presented as live or bookable prices.**
- Nearby places with sort (nearest, popular, category), category filter and View on map.
- Required items are a checklist saved with the trip and are **never** added to the budget.
- Saved trips show budget, breakdown, travel option, required items and chosen places.

## API
| Method | Path | Notes |
|---|---|---|
| GET | `/api/destinations?mood=&q=` | now includes `rating` |
| GET | `/api/destinations/{id}/travel?travelers=` | estimated options and picks |
| GET | `/api/destinations/{id}/places?category=&sort=` | nearby places, `sort` = nearest, popular, category |
| GET | `/api/destinations/{id}/budget/suggest?total=` | suggested split |
| POST | `/api/budget/validate` | allocated / remaining / over_by / state |
| GET, PUT, DELETE | `/api/trips` | PUT now also stores budget, breakdown, travel mode, travellers, places |

Budget is saved through the existing trip endpoint rather than a duplicate one. A split larger than
the total budget is rejected with 422. The travel cost saved with a trip is computed by the server.

## Going live later (no Flutter changes needed)
- `backend/providers.py` has `get_travel_provider()` and `get_places_provider()`. Write a class with the
  same method (live fares, Google Places), return it there, and read any key from an environment
  variable on the server. The app only sees JSON.
- "View on map" opens a plain Google Maps link, which needs no API key. No key is in the app or repo.

## Deploying (Render)
SQLite lives on the server disk. On Render's free tier the disk is wiped on every redeploy and restart,
so **saved trips will be lost**. Either attach a persistent disk and set `WANDER_DB=/var/data/wander.db`,
or move the data to a hosted database (Postgres or MongoDB).
