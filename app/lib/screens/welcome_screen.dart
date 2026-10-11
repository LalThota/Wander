import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// First-run screen: hero picture, headline and a Get started button.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 800;
          final hero = Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: WelcomeArtPainter()),
              // A real photo at assets/images/welcome.jpg replaces the drawing.
              Image.asset(
                'assets/images/welcome.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(140),
                        Colors.transparent,
                        Colors.black.withAlpha(50),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Center(child: BrandLockup()),
                  ),
                ),
              ),
            ],
          );

          final text = Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Explore your journey\nonly with us',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'All your vacation destinations are here, enjoy your holiday.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: kMuted),
                ),
                const SizedBox(height: 28),
                PillButton(label: 'Get started', onPressed: onStart),
              ],
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: hero),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: text,
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: hero),
              SafeArea(top: false, child: text),
            ],
          );
        },
      ),
    );
  }
}
