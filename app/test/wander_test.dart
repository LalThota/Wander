import 'package:flutter_test/flutter_test.dart';
import 'package:wander/models/budget.dart';
import 'package:wander/models/place.dart';
import 'package:wander/models/tourist_place.dart';
import 'package:wander/models/travel.dart';
import 'package:wander/models/trip_draft.dart';
import 'package:wander/util.dart';

void main() {
  final placeJson = {
    'id': 'bali',
    'name': 'Bali',
    'country': 'Indonesia',
    'tagline': 't',
    'season': 'Apr to Oct',
    'flight_time': '6h 30m',
    'temp': 29,
    'per_day': 6500,
    'flight': 28000,
    'mood': 'beach',
    'peaks': false,
    'sky_top': '#3A1C71',
    'sky_bottom': '#FF6F91',
    'sun': '#FFC857',
    'layers': ['#6D2E7C', '#3B1A5A', '#1E0F36'],
    'pack': ['ID proof'],
    'rating': 4.8,
  };

  test('Place parses the API JSON', () {
    final p = Place.fromJson(placeJson);
    expect(p.mood, Mood.beach);
    expect(p.rating, 4.8);
    expect(p.flightHours, 6.5);
    expect(p.estimate(5), 5 * 6500 + 28000);
  });

  test('Place works without a rating (older server)', () {
    final json = {...placeJson}..remove('rating');
    expect(Place.fromJson(json).rating, 4.6);
  });

  test('inr uses Indian digit grouping', () {
    expect(inr(950), '₹950');
    expect(inr(5000), '₹5,000');
    expect(inr(150000), '₹1,50,000');
    expect(inr(1234567), '₹12,34,567');
  });

  test('fmtHours', () {
    expect(fmtHours(12), '12 hrs');
    expect(fmtHours(1), '1 hr');
    expect(fmtHours(2.5), '2 hrs 30 min');
    expect(fmtHours(0.5), '30 min');
  });

  test('budget summary states', () {
    expect(summarize(0, {}).state, BudgetState.unset);
    expect(summarize(30000, {'travel': 25000}).state, BudgetState.under);
    expect(summarize(30000, {'travel': 25000}).remaining, 5000);
    expect(summarize(30000, {'travel': 30000}).state, BudgetState.full);
    final over = summarize(30000, {'travel': 34000});
    expect(over.state, BudgetState.over);
    expect(over.overBy, 4000);
    expect(over.remaining, 0);
    expect(over.isValid, false);
    expect(summarize(0, {'food': 10}).isValid, false);
  });

  test('an old saved trip (no new fields) still loads', () {
    final t = Trip.fromJson({
      'destination_id': 'bali',
      'days': 5,
      'packed': ['Sarong'],
      'total': 60500,
      'updated_at': 1.0,
    });
    expect(t.budget, isNull);
    expect(t.breakdown, isEmpty);
    expect(t.travelMode, isNull);
    expect(t.places, isEmpty);
    expect(t.travelers, 1);
    final draft = TripDraft.fromTrip(t);
    expect(draft.sameAs(t), true);
    expect(draft.problem, isNull);
  });

  test('draft notices changes and over-budget splits', () {
    final t = Trip.fromJson({
      'destination_id': 'bali',
      'days': 5,
      'packed': <String>[],
      'total': 1,
      'updated_at': 1.0,
      'budget': 30000,
      'breakdown': {'travel': 8000},
    });
    final d = TripDraft.fromTrip(t);
    expect(d.sameAs(t), true);
    d.breakdown['food'] = 25000;
    expect(d.sameAs(t), false);
    expect(d.problem, contains('over budget'));
    d.packed.add('ID proof');
    d.breakdown.remove('food');
    expect(d.sameAs(t), false);
  });

  test('travel plan and places parse', () {
    final plan = TravelPlan.fromJson({
      'options': [
        {
          'mode': 'train',
          'cost_per_person': 1100,
          'cost_total': 1100,
          'hours': 10.9,
          'description': 'd',
          'suitable_for': 's',
          'estimated': true,
        }
      ],
      'recommendations': {'cheapest': 'train'},
      'group_size': 4,
      'note': 'estimates',
    });
    expect(plan.byMode('train')?.costTotal, 1100);
    expect(plan.byMode('car'), isNull);

    final places = [
      for (final e in [('a', 9.0, 50), ('b', 2.5, 90), ('c', 5.0, 70)])
        TouristPlace(
          id: e.$1,
          name: e.$1,
          category: 'Nature',
          description: '',
          distanceKm: e.$2,
          popularity: e.$3,
          mapUrl: 'https://www.google.com/maps',
        ),
    ];
    expect(sortPlaces(places, 'nearest').map((p) => p.id), ['b', 'c', 'a']);
    expect(sortPlaces(places, 'popular').map((p) => p.id), ['b', 'c', 'a']);
  });
}
