import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// Splash first, then the welcome screen on a first run, then the app.
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    Widget child;
    if (!_splashDone) {
      child = SplashScreen(
        key: const ValueKey('splash'),
        onDone: () => setState(() => _splashDone = true),
      );
    } else if (!s.prefsReady) {
      child = const Scaffold(
        key: ValueKey('wait'),
        body: LoadingBox(),
      );
    } else if (!s.onboardingSeen) {
      child = WelcomeScreen(
        key: const ValueKey('welcome'),
        onStart: () => s.setOnboardingSeen(true),
      );
    } else {
      child = const Shell(key: ValueKey('shell'));
    }

    return ColoredBox(
      color: kPrimarySoft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: child,
      ),
    );
  }
}
