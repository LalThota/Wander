import 'package:flutter/material.dart';

import 'tourist_place.dart';

Color hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

enum Mood { all, beach, mountain, culture }

extension MoodLabel on Mood {
  String get label {
    switch (this) {
      case Mood.all:
        return 'All';
      case Mood.beach:
        return 'Beach';
      case Mood.mountain:
        return 'Mountains';
      case Mood.culture:
        return 'Culture';
    }
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.country,
    required this.tagline,
    required this.season,
    required this.flightTime,
    required this.temp,
    required this.perDay,
    required this.flight,
    required this.mood,
    required this.peaks,
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.layers,
    required this.pack,
    this.rating = 4.6,
    this.lat,
    this.lng,
  });

  final String id, name, country, tagline, season, flightTime;
  final int temp, perDay, flight;
  final Mood mood;
  final bool peaks;
  final Color skyTop, skyBottom, sun;
  final List<Color> layers;
  final List<String> pack;
  final double rating;
  final double? lat;
  final double? lng;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: j['name'] as String,
        country: j['country'] as String,
        tagline: j['tagline'] as String,
        season: j['season'] as String,
        flightTime: j['flight_time'] as String,
        temp: (j['temp'] as num).toInt(),
        perDay: (j['per_day'] as num).toInt(),
        flight: (j['flight'] as num).toInt(),
        mood: Mood.values.firstWhere(
          (m) => m.name == j['mood'],
          orElse: () => Mood.all,
        ),
        peaks: j['peaks'] as bool,
        skyTop: hexColor(j['sky_top'] as String),
        skyBottom: hexColor(j['sky_bottom'] as String),
        sun: hexColor(j['sun'] as String),
        layers: (j['layers'] as List).map((e) => hexColor(e as String)).toList(),
        pack: (j['pack'] as List).cast<String>(),
        rating: ((j['rating'] as num?) ?? 4.6).toDouble(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  /// Flight time in hours, parsed from text like "6h 30m".
  double get flightHours {
    final m = RegExp(r'(\d+)h\s*(\d+)m').firstMatch(flightTime);
    if (m == null) return 99;
    return int.parse(m.group(1)!) + int.parse(m.group(2)!) / 60;
  }

  /// A very dark version of the sky, used as the page background.
  Color get ink => Color.lerp(skyBottom, Colors.black, 0.82)!;

  /// Rough total: stay plus return flight.
  int estimate(int days) => days * perDay + flight;
}

class Trip {
  const Trip({
    required this.destinationId,
    required this.days,
    required this.packed,
    required this.total,
    required this.updatedAt,
    this.budget,
    this.breakdown = const {},
    this.travelMode,
    this.travelCost,
    this.travelers = 1,
    this.places = const [],
  });

  final String destinationId;
  final int days;

  /// Ticked items of the required-items checklist. Never part of the budget.
  final List<String> packed;

  /// Rough estimate (stay plus return flight) from the server.
  final int total;
  final double updatedAt;

  /// The user's own total budget. Null on trips saved before budgets existed.
  final int? budget;
  final Map<String, int> breakdown;
  final String? travelMode;
  final int? travelCost;
  final int travelers;
  final List<PlaceRef> places;

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        destinationId: j['destination_id'] as String,
        days: (j['days'] as num).toInt(),
        packed: (j['packed'] as List).cast<String>(),
        total: (j['total'] as num).toInt(),
        updatedAt: (j['updated_at'] as num).toDouble(),
        // Every field below is optional so older saved trips still load.
        budget: (j['budget'] as num?)?.toInt(),
        breakdown: ((j['breakdown'] as Map?) ?? const {})
            .map<String, int>((k, v) => MapEntry(k as String, (v as num).toInt())),
        travelMode: j['travel_mode'] as String?,
        travelCost: (j['travel_cost'] as num?)?.toInt(),
        travelers: ((j['travelers'] as num?) ?? 1).toInt(),
        places: ((j['places'] as List?) ?? const [])
            .map((e) => PlaceRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
