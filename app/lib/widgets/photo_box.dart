import 'package:flutter/material.dart';

import '../models/place.dart';
import 'scene_painter.dart';

/// Shows a destination picture. A real photo from assets/images wins when it
/// exists (bali.jpg, bali_1.jpg ...), otherwise the painted scene is shown.
class PhotoBox extends StatelessWidget {
  const PhotoBox({
    super.key,
    required this.p,
    this.variant = 0,
    this.radius = 20,
  });

  final Place p;
  final int variant;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = variant == 0 ? p.id : '${p.id}_$variant';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ScenePainter(p, variant: variant),
            child: const SizedBox.expand(),
          ),
          Image.asset(
            'assets/images/$name.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
