import 'package:flutter/material.dart';

extension ColorFade on Color {
  /// Same colour at the given opacity (0 to 1).
  Color fade(double opacity) =>
      withAlpha((clampD(opacity, 0, 1) * 255).round());
}

double clampD(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// Rupees with Indian digit grouping: 1234567 -> ₹12,34,567
String inr(num v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final last = s.substring(s.length - 3);
  final rest = s
      .substring(0, s.length - 3)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+$)'), (m) => '${m[1]},');
  return '₹$rest,$last';
}

/// 2.5 -> "2 hrs 30 min", 12 -> "12 hrs", 0.5 -> "30 min"
String fmtHours(double hours) {
  final mins = ((hours * 60) / 5).round() * 5;
  final h = mins ~/ 60;
  final m = mins % 60;
  final hs = '$h hr${h == 1 ? '' : 's'}';
  if (h == 0) return '$m min';
  return m == 0 ? hs : '$hs $m min';
}
