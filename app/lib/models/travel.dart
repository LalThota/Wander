import 'package:flutter/material.dart';

IconData modeIcon(String mode) {
  switch (mode) {
    case 'train':
      return Icons.train;
    case 'flight':
      return Icons.flight;
    case 'bus':
      return Icons.directions_bus;
    case 'car':
      return Icons.directions_car;
    default:
      return Icons.commute;
  }
}

String modeLabel(String mode) =>
    mode.isEmpty ? mode : mode[0].toUpperCase() + mode.substring(1);

/// One way of getting there. Values are estimates, not live fares.
class TravelOption {
  const TravelOption({
    required this.mode,
    required this.costPerPerson,
    required this.costTotal,
    required this.hours,
    required this.description,
    required this.suitableFor,
    required this.estimated,
  });

  final String mode, description, suitableFor;
  final int costPerPerson, costTotal;
  final double hours;
  final bool estimated;

  factory TravelOption.fromJson(Map<String, dynamic> j) => TravelOption(
        mode: j['mode'] as String,
        costPerPerson: (j['cost_per_person'] as num).toInt(),
        costTotal: (j['cost_total'] as num).toInt(),
        hours: (j['hours'] as num).toDouble(),
        description: j['description'] as String,
        suitableFor: j['suitable_for'] as String,
        estimated: (j['estimated'] as bool?) ?? true,
      );
}

class TravelPlan {
  const TravelPlan({
    required this.options,
    required this.recommendations,
    required this.groupSize,
    required this.note,
  });

  final List<TravelOption> options;

  /// cheapest, fastest, best_value, best_group -> mode
  final Map<String, String> recommendations;
  final int groupSize;
  final String note;

  factory TravelPlan.fromJson(Map<String, dynamic> j) => TravelPlan(
        options: (j['options'] as List)
            .map((e) => TravelOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendations: ((j['recommendations'] as Map?) ?? const {})
            .map<String, String>((k, v) => MapEntry(k as String, v as String)),
        groupSize: ((j['group_size'] as num?) ?? 4).toInt(),
        note: (j['note'] as String?) ?? 'These are estimates, not live prices.',
      );

  TravelOption? byMode(String mode) {
    for (final o in options) {
      if (o.mode == mode) return o;
    }
    return null;
  }
}
