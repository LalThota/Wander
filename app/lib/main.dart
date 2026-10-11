import 'package:flutter/material.dart';

import 'screens/root.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() => runApp(const WanderApp());

class WanderApp extends StatefulWidget {
  const WanderApp({super.key});

  @override
  State<WanderApp> createState() => _WanderAppState();
}

class _WanderAppState extends State<WanderApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    // Loads settings and data while the splash animation plays.
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope sits above MaterialApp so pushed screens can read it too.
    return AppScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Wander',
        theme: buildTheme(),
        home: const Root(),
      ),
    );
  }
}
