import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../util.dart';

/// Bright daytime illustration for a destination: sky, clouds, then a beach,
/// mountain or heritage scene depending on the mood. [variant] (0 to 3)
/// changes the sky and cloud layout for the "More images" thumbnails.
/// Real photos in assets/images replace these (see PhotoBox).
class ScenePainter extends CustomPainter {
  ScenePainter(this.p, {this.variant = 0});

  final Place p;
  final int variant;

  static const _skies = <List<Color>>[
    [Color(0xFF4DB3F0), Color(0xFFD9F1FC)],
    [Color(0xFF6CC1F3), Color(0xFFFBEBD2)],
    [Color(0xFF3C97DE), Color(0xFFBFE5F8)],
    [Color(0xFF8DB0E6), Color(0xFFF8D9C8)],
  ];

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _skies[variant % _skies.length],
        ).createShader(rect),
    );

    final rnd = math.Random(p.id.hashCode * 31 + variant);

    final sun = Offset(w * (0.2 + 0.6 * ((variant * 0.37 + 0.3) % 1.0)), h * 0.16);
    c.drawCircle(
      sun,
      w * 0.13,
      Paint()
        ..color = const Color(0xFFFFF6D6).fade(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    c.drawCircle(sun, w * 0.05, Paint()..color = const Color(0xFFFFF3C4));

    for (var i = 0; i < 3; i++) {
      _cloud(
        c,
        Offset(w * (0.1 + 0.8 * rnd.nextDouble()), h * (0.08 + 0.22 * rnd.nextDouble())),
        w * (0.1 + 0.08 * rnd.nextDouble()),
      );
    }

    switch (p.mood) {
      case Mood.mountain:
        _mountain(c, s, rnd);
      case Mood.culture:
        _culture(c, s);
      default:
        _beach(c, s);
    }
  }

  void _cloud(Canvas c, Offset o, double r) {
    final paint = Paint()..color = Colors.white.fade(0.92);
    c.drawCircle(o, r * 0.55, paint);
    c.drawCircle(o + Offset(r * 0.55, r * 0.1), r * 0.45, paint);
    c.drawCircle(o + Offset(-r * 0.55, r * 0.15), r * 0.38, paint);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + Offset(0, r * 0.3), width: r * 2.0, height: r * 0.5),
        Radius.circular(r * 0.25),
      ),
      paint,
    );
  }

  // Turquoise lagoon with a boardwalk and bungalows on stilts.
  void _beach(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final horizon = h * 0.56;

    final island = Path()
      ..moveTo(0, horizon)
      ..quadraticBezierTo(w * 0.12, horizon - h * 0.2, w * 0.28, horizon - h * 0.06)
      ..quadraticBezierTo(w * 0.36, horizon - h * 0.16, w * 0.5, horizon)
      ..close();
    c.drawPath(island, Paint()..color = const Color(0xFF6F9C8E));

    final sea = Rect.fromLTWH(0, horizon, w, h - horizon);
    c.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FE6EA), Color(0xFF2CC1D2), Color(0xFF1AA7BE)],
        ).createShader(sea),
    );
    final wave = Paint()
      ..color = Colors.white.fade(0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 4; i++) {
      final y = horizon + (h - horizon) * (i / 5);
      final path = Path()..moveTo(w * 0.02, y);
      for (var x = w * 0.02; x < w * 0.98; x += 14) {
        path.relativeQuadraticBezierTo(4, -3, 7, 0);
        path.relativeQuadraticBezierTo(4, 3, 7, 0);
      }
      c.drawPath(path, wave);
    }

    final walk = Path()
      ..moveTo(w * 0.1, h)
      ..lineTo(w * 0.36, h)
      ..lineTo(w * 0.66, horizon + h * 0.07)
      ..lineTo(w * 0.6, horizon + h * 0.07)
      ..close();
    c.drawPath(walk, Paint()..color = const Color(0xFFCFA97F));
    final plank = Paint()
      ..color = const Color(0xFFB88D63)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 9; i++) {
      final t = i / 9;
      final y = h - (h - horizon - h * 0.07) * t;
      final left = w * 0.1 + (w * 0.5 * t);
      final right = w * 0.36 + (w * 0.24 * t);
      c.drawLine(Offset(left, y), Offset(right, y), plank);
    }

    for (var i = 4; i >= 0; i--) {
      final t = i / 4;
      final scale = 1.0 - 0.7 * t;
      _hut(
        c,
        Offset(w * (0.8 - 0.14 * t), horizon + h * (0.34 - 0.27 * t)),
        w * 0.2 * scale,
      );
    }
  }

  void _hut(Canvas c, Offset base, double size) {
    final leg = Paint()
      ..color = const Color(0xFF8A6A4A)
      ..strokeWidth = math.max(1.5, size * 0.03);
    for (final dx in [-0.4, -0.1, 0.2, 0.45]) {
      c.drawLine(
        base + Offset(size * dx, 0),
        base + Offset(size * dx, size * 0.25),
        leg,
      );
    }
    c.drawRect(
      Rect.fromLTWH(base.dx - size * 0.5, base.dy - size * 0.05, size, size * 0.06),
      Paint()..color = const Color(0xFFD9B88F),
    );
    final bodyRect = Rect.fromLTWH(
      base.dx - size * 0.4,
      base.dy - size * 0.33,
      size * 0.8,
      size * 0.28,
    );
    c.drawRect(bodyRect, Paint()..color = const Color(0xFFF4E6D0));
    c.drawRect(
      Rect.fromLTWH(base.dx - size * 0.06, base.dy - size * 0.24, size * 0.12, size * 0.19),
      Paint()..color = const Color(0xFF9B7A58),
    );
    final roof = Path()
      ..moveTo(base.dx - size * 0.55, base.dy - size * 0.32)
      ..lineTo(base.dx, base.dy - size * 0.68)
      ..lineTo(base.dx + size * 0.55, base.dy - size * 0.32)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFA67C52));
  }

  // Three ridges with snow caps, a lake and pines.
  void _mountain(Canvas c, Size s, math.Random rnd) {
    final w = s.width;
    final h = s.height;
    const bases = [0.50, 0.58, 0.66];
    const amps = [0.28, 0.20, 0.12];
    const colors = [Color(0xFF9FB8CC), Color(0xFF6F93AA), Color(0xFF3F7D5C)];

    for (var i = 0; i < 3; i++) {
      final base = h * bases[i];
      final path = Path()
        ..moveTo(-20, h)
        ..lineTo(-20, base);
      final peaks = <Offset>[];
      var x = -20.0;
      while (x < w + 20) {
        x += w * (0.10 + 0.12 * rnd.nextDouble());
        final y = base - h * amps[i] * (0.35 + 0.65 * rnd.nextDouble());
        path.lineTo(x, y);
        peaks.add(Offset(x, y));
      }
      path
        ..lineTo(w + 20, base)
        ..lineTo(w + 20, h)
        ..close();
      c.drawPath(path, Paint()..color = colors[i]);

      if (i == 0) {
        for (final pk in peaks) {
          if (pk.dy < base - h * amps[0] * 0.6) {
            final cap = Path()
              ..moveTo(pk.dx, pk.dy)
              ..lineTo(pk.dx - w * 0.03, pk.dy + h * 0.045)
              ..lineTo(pk.dx - w * 0.01, pk.dy + h * 0.035)
              ..lineTo(pk.dx + w * 0.005, pk.dy + h * 0.05)
              ..lineTo(pk.dx + w * 0.03, pk.dy + h * 0.045)
              ..close();
            c.drawPath(cap, Paint()..color = Colors.white.fade(0.95));
          }
        }
      }
    }

    final lake = Rect.fromLTWH(0, h * 0.74, w, h * 0.26);
    c.drawRect(
      lake,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FE0D8), Color(0xFF28B5B8)],
        ).createShader(lake),
    );
    final tree = Paint()..color = const Color(0xFF1F5A44);
    for (var i = 0; i < 8; i++) {
      final left = i < 4;
      final tx = left ? w * (0.02 + 0.05 * i) : w * (0.98 - 0.05 * (i - 4));
      final ty = h * (0.78 + 0.03 * (i % 4));
      final th = h * (0.1 + 0.03 * ((i * 7) % 3));
      final t = Path()
        ..moveTo(tx, ty - th)
        ..lineTo(tx - th * 0.28, ty)
        ..lineTo(tx + th * 0.28, ty)
        ..close();
      c.drawPath(t, tree);
    }
  }

  // Sandstone palace on a hill with domes and arches.
  void _culture(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;

    final hills = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.25, h * 0.46, w * 0.5, h * 0.6)
      ..quadraticBezierTo(w * 0.78, h * 0.44, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(hills, Paint()..color = const Color(0xFFA9C8B8));

    final ground = Rect.fromLTWH(0, h * 0.74, w, h * 0.26);
    c.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8CC084), Color(0xFF68A872)],
        ).createShader(ground),
    );

    const stone = Color(0xFFE9B98F);
    const stoneLight = Color(0xFFF3CFAA);
    const shade = Color(0xFFB87D52);

    final baseY = h * 0.74;
    c.drawRect(Rect.fromLTWH(w * 0.16, h * 0.48, w * 0.68, baseY - h * 0.48), Paint()..color = stone);
    for (var i = 0; i < 12; i++) {
      c.drawRect(
        Rect.fromLTWH(w * (0.16 + 0.68 * i / 12), h * 0.455, w * 0.68 / 12 * 0.6, h * 0.03),
        Paint()..color = stone,
      );
    }
    c.drawRect(Rect.fromLTWH(w * 0.42, h * 0.34, w * 0.16, h * 0.14), Paint()..color = stoneLight);
    _dome(c, Offset(w * 0.5, h * 0.34), w * 0.16, stoneLight);
    for (final cx in [0.2, 0.8]) {
      c.drawRect(Rect.fromLTWH(w * (cx - 0.04), h * 0.36, w * 0.08, baseY - h * 0.36), Paint()..color = stoneLight);
      _dome(c, Offset(w * cx, h * 0.36), w * 0.08, stone);
    }
    for (var i = 0; i < 5; i++) {
      final x = w * (0.26 + 0.12 * i);
      final arch = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, h * 0.56, w * 0.07, h * 0.18),
        topLeft: Radius.circular(w * 0.035),
        topRight: Radius.circular(w * 0.035),
      );
      c.drawRRect(arch, Paint()..color = shade);
    }
    final path = Path()
      ..moveTo(w * 0.4, baseY)
      ..lineTo(w * 0.6, baseY)
      ..lineTo(w * 0.78, h)
      ..lineTo(w * 0.22, h)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFF0DDBF));
  }

  void _dome(Canvas c, Offset base, double width, Color color) {
    c.drawArc(
      Rect.fromCenter(center: base, width: width, height: width),
      math.pi,
      math.pi,
      true,
      Paint()..color = color,
    );
    c.drawLine(
      base - Offset(0, width * 0.5),
      base - Offset(0, width * 0.7),
      Paint()
        ..color = const Color(0xFFB87D52)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.p != p || old.variant != variant;
}
