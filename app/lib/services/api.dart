import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/place.dart';
import '../models/tourist_place.dart';
import '../models/travel.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Api {
  Api({http.Client? client}) : _c = client ?? http.Client();
  final http.Client _c;
  // Free hosting can take up to a minute to wake up on the first request.
  static const _timeout = Duration(seconds: 45);

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$apiBase$path').replace(queryParameters: query);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final r = await request().timeout(_timeout);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
      }
      throw ApiException('The server answered ${r.statusCode}. Try again.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to answer.');
    } catch (_) {
      throw ApiException("Can't reach the server at $apiBase. Is it running?");
    }
  }

  Future<List<Place>> places() async {
    final d = await _send(() => _c.get(_u('/api/destinations')));
    return (d as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Trip>> trips(String clientId) async {
    final d = await _send(
      () => _c.get(_u('/api/trips', {'client_id': clientId})),
    );
    return (d as List)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> saveTrip({
    required String clientId,
    required String destinationId,
    required int days,
    required List<String> packed,
    int? budget,
    Map<String, int> breakdown = const {},
    String? travelMode,
    int travelers = 1,
    List<PlaceRef> places = const [],
  }) async {
    final d = await _send(
      () => _c.put(
        _u('/api/trips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'destination_id': destinationId,
          'days': days,
          'packed': packed,
          'budget': budget,
          'breakdown': breakdown,
          'travel_mode': travelMode,
          'travelers': travelers,
          'places': [
            for (final p in places) {'id': p.id, 'name': p.name},
          ],
        }),
      ),
    );
    return Trip.fromJson(d as Map<String, dynamic>);
  }

  /// A suggested split of [total] across the budget categories.
  Future<Map<String, int>> suggestBudget(String destinationId, int total) async {
    final d = await _send(
      () => _c.get(
        _u('/api/destinations/$destinationId/budget/suggest', {'total': '$total'}),
      ),
    );
    final m = (d as Map<String, dynamic>)['breakdown'] as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<TravelPlan> travel(String destinationId, int travelers) async {
    final d = await _send(
      () => _c.get(
        _u('/api/destinations/$destinationId/travel', {'travelers': '$travelers'}),
      ),
    );
    return TravelPlan.fromJson(d as Map<String, dynamic>);
  }

  Future<List<TouristPlace>> nearby(String destinationId) async {
    final d = await _send(
      () => _c.get(_u('/api/destinations/$destinationId/places')),
    );
    return (d as List)
        .map((e) => TouristPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteTrip(String clientId, String destinationId) async {
    await _send(
      () => _c.delete(_u('/api/trips/$destinationId', {'client_id': clientId})),
    );
  }
}
