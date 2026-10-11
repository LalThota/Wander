import 'package:flutter/material.dart';

class BudgetCategory {
  const BudgetCategory(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

/// Keys match the backend's budget categories.
const budgetCategories = <BudgetCategory>[
  BudgetCategory('travel', 'Travel', Icons.flight_takeoff),
  BudgetCategory('stay', 'Stay', Icons.hotel_outlined),
  BudgetCategory('food', 'Food', Icons.restaurant_outlined),
  BudgetCategory('transport', 'Local transport', Icons.directions_bus_outlined),
  BudgetCategory('activities', 'Activities', Icons.local_activity_outlined),
  BudgetCategory('other', 'Other', Icons.more_horiz),
];

String categoryLabel(String key) {
  for (final c in budgetCategories) {
    if (c.key == key) return c.label;
  }
  return key;
}

enum BudgetState { unset, under, full, over }

/// Total budget vs. what has been given to categories.
class BudgetSummary {
  const BudgetSummary(this.total, this.allocated);

  final int total;
  final int allocated;

  int get remaining => total > allocated ? total - allocated : 0;
  int get overBy => allocated > total ? allocated - total : 0;

  BudgetState get state {
    if (total <= 0) return BudgetState.unset;
    if (allocated > total) return BudgetState.over;
    if (allocated == total) return BudgetState.full;
    return BudgetState.under;
  }

  /// Without a total nothing can be allocated; with one, the split must fit.
  bool get isValid => total <= 0 ? allocated == 0 : allocated <= total;
}

BudgetSummary summarize(int total, Map<String, int> parts) =>
    BudgetSummary(total, parts.values.fold(0, (a, b) => a + b));
