import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/place.dart';
import '../models/tourist_place.dart';
import '../models/travel.dart';
import '../models/trip_draft.dart';
import '../services/api.dart';

/// All app data lives here. Screens read it through [AppScope].
class AppState extends ChangeNotifier {
  AppState({Api? api}) : api = api ?? Api();

  final Api api;
  late String clientId;

  List<Place> places = [];
  Map<String, Trip> trips = {};
  Mood mood = Mood.all;
  String query = '';
  bool loading = true;
  String? error;

  SharedPreferences? _prefs;
  bool prefsReady = false;
  bool onboardingSeen = false;
  String userName = '';

  // Destination info is cached for the session so it is fetched only once.
  final Map<String, TravelPlan> _travelCache = {};
  final Map<String, List<TouristPlace>> _placesCache = {};

  /// Bumps when filters are cleared so the search box resets its text.
  int filterEpoch = 0;

  List<Place> get visible {
    final q = query.trim().toLowerCase();
    return places.where((p) {
      final okMood = mood == Mood.all || p.mood == mood;
      final okQuery = q.isEmpty ||
          '${p.name} ${p.country} ${p.tagline}'.toLowerCase().contains(q);
      return okMood && okQuery;
    }).toList();
  }

  Place? placeById(String id) {
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    var id = prefs.getString('client_id');
    if (id == null) {
      id = _newId();
      await prefs.setString('client_id', id);
    }
    final customUrl = prefs.getString('custom_api_url');
    if (customUrl != null) setCustomServerUrl(customUrl);
    clientId = id;
    onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    userName = prefs.getString('user_name') ?? '';
    prefsReady = true;
    notifyListeners();
    await load();
  }

  Future<void> setCustomApiUrl(String? url) async {
    final clean = url?.trim();
    if (clean == null || clean.isEmpty) {
      await _prefs?.remove('custom_api_url');
      setCustomServerUrl(null);
    } else {
      await _prefs?.setString('custom_api_url', clean);
      setCustomServerUrl(clean);
    }
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final p = await api.places();
      final t = await api.trips(clientId);
      places = p;
      trips = {for (final x in t) x.destinationId: x};
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setOnboardingSeen(bool seen) async {
    onboardingSeen = seen;
    notifyListeners();
    await _prefs?.setBool('onboarding_seen', seen);
  }

  Future<void> setUserName(String name) async {
    userName = name.trim();
    notifyListeners();
    await _prefs?.setString('user_name', userName);
  }

  void setMood(Mood m) {
    mood = m;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void clearFilters() {
    mood = Mood.all;
    query = '';
    filterEpoch++;
    notifyListeners();
  }

  /// Estimated travel options. Throws [ApiException] on failure.
  Future<TravelPlan> travelPlan(String destinationId, int travelers) async {
    final key = '$destinationId|$travelers';
    final hit = _travelCache[key];
    if (hit != null) return hit;
    final plan = await api.travel(destinationId, travelers);
    _travelCache[key] = plan;
    return plan;
  }

  /// Nearby tourist places. Throws [ApiException] on failure.
  Future<List<TouristPlace>> nearbyPlaces(String destinationId) async {
    final hit = _placesCache[destinationId];
    if (hit != null) return hit;
    final places = await api.nearby(destinationId);
    _placesCache[destinationId] = places;
    return places;
  }

  /// Throws [ApiException] on failure.
  Future<Map<String, int>> suggestBudget(String destinationId, int total) =>
      api.suggestBudget(destinationId, total);

  /// Returns an error message, or null when it worked.
  Future<String?> saveTrip(Place p, TripDraft d) async {
    try {
      final t = await api.saveTrip(
        clientId: clientId,
        destinationId: p.id,
        days: d.days,
        packed: d.packed.toList(),
        budget: d.budgetValue > 0 ? d.budgetValue : null,
        breakdown: d.cleanBreakdown,
        travelMode: d.travelMode,
        travelers: d.travelers,
        places: [
          for (final e in d.places.entries) PlaceRef(id: e.key, name: e.value),
        ],
      );
      trips = {...trips, p.id: t};
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> removeTrip(String destinationId) async {
    try {
      await api.deleteTrip(clientId, destinationId);
      trips = {...trips}..remove(destinationId);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  static String _newId() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}

/// Hands [AppState] to any widget below it: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  /// Rebuilds the calling widget whenever the state changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state once without subscribing (safe in initState).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
