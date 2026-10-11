import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals, setEquals;

import '../util.dart';
import 'budget.dart';
import 'place.dart';
import 'tourist_place.dart';

/// The trip being planned on the detail screen, before it is saved.
/// Required items (packed) live here too but are never part of the budget.
class TripDraft {
  TripDraft({
    this.days = 5,
    this.budget,
    Map<String, int>? breakdown,
    this.travelMode,
    this.travelers = 1,
    Set<String>? packed,
    Map<String, String>? places,
  })  : breakdown = <String, int>{...?breakdown},
        packed = <String>{...?packed},
        places = <String, String>{...?places};

  factory TripDraft.fromTrip(Trip? t) => TripDraft(
        days: math.min(21, math.max(2, t?.days ?? 5)),
        budget: t?.budget,
        breakdown: t?.breakdown,
        travelMode: t?.travelMode,
        travelers: t?.travelers ?? 1,
        packed: t?.packed.toSet(),
        places: {for (final p in t?.places ?? const <PlaceRef>[]) p.id: p.name},
      );

  int days;
  int? budget;
  final Map<String, int> breakdown;
  String? travelMode;
  int travelers;
  final Set<String> packed;

  /// Chosen tourist places, id -> name.
  final Map<String, String> places;

  int get budgetValue => budget ?? 0;
  BudgetSummary get summary => summarize(budgetValue, breakdown);

  /// Why this draft can't be saved yet, or null when it is fine.
  String? get problem {
    final s = summary;
    if (s.isValid) return null;
    if (s.total <= 0) return 'Set a total budget before splitting it.';
    return 'Your split is over budget by ${inr(s.overBy)}.';
  }

  static Map<String, int> _clean(Map<String, int> m) =>
      {for (final e in m.entries) if (e.value > 0) e.key: e.value};

  /// Breakdown without empty categories, as sent to the server.
  Map<String, int> get cleanBreakdown => _clean(breakdown);

  /// True when nothing differs from the saved trip [t].
  bool sameAs(Trip? t) {
    if (t == null) return false;
    return days == t.days &&
        budgetValue == (t.budget ?? 0) &&
        mapEquals(_clean(breakdown), _clean(t.breakdown)) &&
        travelMode == t.travelMode &&
        travelers == t.travelers &&
        setEquals(packed, t.packed.toSet()) &&
        setEquals(places.keys.toSet(), t.places.map((p) => p.id).toSet());
  }
}
