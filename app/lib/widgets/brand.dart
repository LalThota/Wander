import 'package:flutter/material.dart';

import '../util.dart';

/// The Wander mark: a rising sun behind two peaks. [t] runs 0 to 1.
class LogoMarkPainter extends CustomPainter {
  LogoMarkPainter(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final rise = Curves.easeOutCubic.transform(clampD(t / 0.65, 0, 1));
    final sun = Offset(w * 0.5, h * (0.66 - 0.32 * rise));

    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, w, h * 0.86));
    c.drawCircle(
      sun,
      w * 0.34,
      Paint()
        ..color = const Color(0xFFFFE08A).fade(0.45 * rise)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    c.drawCircle(sun, w * 0.2, Paint()..color = const Color(0xFFFFD166));
    c.restore();

    final back = Path()
      ..moveTo(w * 0.04, h * 0.86)
      ..lineTo(w * 0.36, h * 0.44)
      ..lineTo(w * 0.56, h * 0.68)
      ..lineTo(w * 0.72, h * 0.5)
      ..lineTo(w * 0.96, h * 0.86)
      ..close();
    c.drawPath(back, Paint()..color = Colors.white.fade(0.7));
    final front = Path()
      ..moveTo(0, h * 0.92)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.5, h * 0.8)
      ..lineTo(w * 0.7, h * 0.62)
      ..lineTo(w, h * 0.92)
      ..close();
    c.drawPath(front, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(LogoMarkPainter old) => old.t != t;
}

/// Small static mark plus "Wander", used on the welcome screen.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.color = Colors.white});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(painter: LogoMarkPainter(1)),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'wander',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Tiny map tile used on the "Your trips" card.
class MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9EEF3));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(0, s.height * 0.7)
        ..quadraticBezierTo(s.width * 0.4, s.height * 0.3, s.width, s.height * 0.5),
      road,
    );
    c.drawLine(Offset(s.width * 0.3, 0), Offset(s.width * 0.55, s.height), road);
    c.drawCircle(Offset(s.width * 0.55, s.height * 0.42), 9, Paint()..color = const Color(0xFF14AAF5).fade(0.25));
    c.drawCircle(Offset(s.width * 0.55, s.height * 0.42), 5, Paint()..color = const Color(0xFF14AAF5));
  }

  @override
  bool shouldRepaint(MiniMapPainter old) => false;
}

/// The welcome hero: a camper van on a beach under a bright sky.
class WelcomeArtPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3FA9F0), Color(0xFF9BD6F7), Color(0xFFE4F5FD), Colors.white],
          stops: [0, 0.45, 0.8, 1],
        ).createShader(rect),
    );

    final cloud = Paint()..color = Colors.white.fade(0.95);
    final cc = Offset(w * 0.42, h * 0.2);
    c.drawCircle(cc, w * 0.1, cloud);
    c.drawCircle(cc + Offset(w * 0.1, h * 0.01), w * 0.085, cloud);
    c.drawCircle(cc + Offset(-w * 0.1, h * 0.02), w * 0.07, cloud);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: cc + Offset(0, h * 0.03), width: w * 0.36, height: h * 0.06),
        Radius.circular(h * 0.03),
      ),
      cloud,
    );
    c.drawCircle(Offset(w * 0.86, h * 0.12), w * 0.05, cloud);
    c.drawCircle(Offset(w * 0.92, h * 0.13), w * 0.04, cloud);

    final sea = Rect.fromLTWH(0, h * 0.5, w, h * 0.16);
    c.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FE0E8), Color(0xFF2FC0D4)],
        ).createShader(sea),
    );
    c.drawRect(
      Rect.fromLTWH(0, h * 0.64, w, h * 0.02),
      Paint()..color = Colors.white.fade(0.7),
    );

    final sand = Rect.fromLTWH(0, h * 0.66, w, h * 0.34);
    c.drawRect(
      sand,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3E4C8), Colors.white],
        ).createShader(sand),
    );

    _van(c, Rect.fromLTWH(w * 0.08, h * 0.5, w * 0.7, h * 0.3));
  }

  void _van(Canvas c, Rect r) {
    final w = r.width;
    final h = r.height;
    // shadow
    c.drawOval(
      Rect.fromLTWH(r.left + w * 0.04, r.bottom - h * 0.04, w * 0.92, h * 0.1),
      Paint()..color = Colors.black.fade(0.08),
    );
    // roof rack and bags
    final rackY = r.top + h * 0.1;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left + w * 0.18, rackY, w * 0.56, h * 0.025), const Radius.circular(3)),
      Paint()..color = const Color(0xFF5B6B78),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left + w * 0.24, rackY - h * 0.16, w * 0.2, h * 0.16), const Radius.circular(6)),
      Paint()..color = const Color(0xFFE4574D),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left + w * 0.47, rackY - h * 0.12, w * 0.18, h * 0.12), const Radius.circular(6)),
      Paint()..color = const Color(0xFFF2B33D),
    );
    // body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left, r.top + h * 0.13, w, h * 0.72),
      Radius.circular(h * 0.14),
    );
    c.drawRRect(body, Paint()..color = const Color(0xFFCFE9F5));
    // white roof half
    c.save();
    c.clipRRect(body);
    c.drawRect(
      Rect.fromLTWH(r.left, r.top + h * 0.13, w, h * 0.3),
      Paint()..color = Colors.white,
    );
    c.restore();
    // windows
    final win = Paint()..color = const Color(0xFF4A6676);
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + w * (0.12 + 0.2 * i), r.top + h * 0.2, w * 0.16, h * 0.2),
          const Radius.circular(8),
        ),
        win,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + w * 0.76, r.top + h * 0.2, w * 0.18, h * 0.22),
        const Radius.circular(10),
      ),
      win,
    );
    // life ring
    final ringC = Offset(r.left + w * 0.3, r.top + h * 0.62);
    c.drawCircle(
      ringC,
      h * 0.1,
      Paint()
        ..color = const Color(0xFFFF8A3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.05,
    );
    // headlight and bumper
    c.drawCircle(Offset(r.left + w * 0.93, r.top + h * 0.62), h * 0.045, Paint()..color = const Color(0xFFFFE08A));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + w * 0.02, r.top + h * 0.8, w * 0.96, h * 0.06),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFE6EDF2),
    );
    // wheels
    for (final fx in [0.2, 0.78]) {
      final wc = Offset(r.left + w * fx, r.top + h * 0.88);
      c.drawCircle(wc, h * 0.13, Paint()..color = const Color(0xFF2A3038));
      c.drawCircle(wc, h * 0.06, Paint()..color = const Color(0xFFD9E1E8));
    }
  }

  @override
  bool shouldRepaint(WelcomeArtPainter old) => false;
}
