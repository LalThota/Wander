import 'package:flutter/material.dart';

/// Id and name of a place saved with a trip.
class PlaceRef {
  const PlaceRef({required this.id, required this.name});
  final String id;
  final String name;

  factory PlaceRef.fromJson(Map<String, dynamic> j) =>
      PlaceRef(id: j['id'] as String, name: j['name'] as String);
}

class TouristPlace {
  const TouristPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.distanceKm,
    required this.popularity,
    required this.mapUrl,
    this.imageUrl,
    this.lat,
    this.lng,
  });

  final String id, name, category, description, mapUrl;
  final String? imageUrl;
  final double distanceKm;
  final int popularity;
  final double? lat;
  final double? lng;

  factory TouristPlace.fromJson(Map<String, dynamic> j) => TouristPlace(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        description: j['description'] as String,
        distanceKm: (j['distance_km'] as num).toDouble(),
        popularity: (j['popularity'] as num).toInt(),
        mapUrl: j['map_url'] as String,
        imageUrl: j['image_url'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Beaches':
      return Icons.beach_access;
    case 'Historical':
      return Icons.account_balance;
    case 'Nature':
      return Icons.park;
    case 'Adventure':
      return Icons.hiking;
    case 'Religious':
      return Icons.self_improvement;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Food':
      return Icons.restaurant;
    case 'Entertainment':
      return Icons.local_activity;
    default:
      return Icons.place;
  }
}

/// sort is one of: nearest, popular, category.
List<TouristPlace> sortPlaces(List<TouristPlace> list, String sort) {
  final out = [...list];
  int byDistance(TouristPlace a, TouristPlace b) =>
      a.distanceKm.compareTo(b.distanceKm);
  switch (sort) {
    case 'popular':
      out.sort((a, b) {
        final c = b.popularity.compareTo(a.popularity);
        return c != 0 ? c : byDistance(a, b);
      });
    case 'category':
      out.sort((a, b) {
        final c = a.category.compareTo(b.category);
        return c != 0 ? c : byDistance(a, b);
      });
    default:
      out.sort(byDistance);
  }
  return out;
}
