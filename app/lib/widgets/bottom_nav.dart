import 'package:flutter/material.dart';

import '../theme.dart';

/// Floating white bar. The active tab is a blue circle.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onTap, this.badge = 0});

  final int index;
  final ValueChanged<int> onTap;

  /// Number shown on the Saved tab.
  final int badge;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Saved trips'),
    (Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kLine),
        boxShadow: softShadow(0.12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++) _item(i),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final on = i == index;
    final it = _items[i];
    Widget icon = Icon(on ? it.$1 : it.$2, size: 24, color: on ? Colors.white : kMuted);
    if (i == 1 && badge > 0) {
      icon = Badge(
        label: Text('$badge'),
        backgroundColor: on ? Colors.white : kPrimary,
        textColor: on ? kPrimary : Colors.white,
        child: icon,
      );
    }
    return Semantics(
      button: true,
      selected: on,
      label: it.$3,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? kPrimary : Colors.transparent,
            boxShadow: on
                ? [BoxShadow(color: kPrimary.withAlpha(90), blurRadius: 14, offset: const Offset(0, 6))]
                : null,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
