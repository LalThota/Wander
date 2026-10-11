import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/bottom_nav.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// Four tabs with a floating bottom bar. Content is centred and capped in
/// width, so phones, tablets and desktop windows all look right.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              HomeScreen(onViewAll: () => _go(2), onOpenTrips: () => _go(1)),
              SavedScreen(onBrowse: () => _go(0)),
              const ExploreScreen(),
              const ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: BottomNav(index: _tab, onTap: _go, badge: s.trips.length),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
