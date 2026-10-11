import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/destination_card.dart';
import '../widgets/search_and_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onViewAll, required this.onOpenTrips});

  final VoidCallback onViewAll;
  final VoidCallback onOpenTrips;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searching = false;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _notifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 40, color: kPrimary),
              SizedBox(height: 12),
              Text(
                "You're all caught up",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'New alerts about your trips will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.loading && s.places.isEmpty) {
      return const LoadingBox(
        message: 'Connecting to the server...\nThe first load can take up to a minute.',
      );
    }
    if (s.error != null && s.places.isEmpty) {
      return ErrorBox(message: s.error!, onRetry: s.load);
    }

    final list = s.visible;
    final top = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
    final near = [...list]..sort((a, b) => a.flightHours.compareTo(b.flightHours));
    final tripCount = s.trips.length;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.only(top: 20, bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.userName.isEmpty ? 'Traveller' : s.userName,
                            style: const TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                      tooltip: _searching ? 'Close search' : 'Search',
                      onTap: () {
                        if (_searching) s.setQuery('');
                        setState(() => _searching = !_searching);
                      },
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      onTap: _notifications,
                    ),
                  ],
                ),
              ),
              if (_searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: SearchBox(
                    key: ValueKey(s.filterEpoch),
                    autofocus: true,
                    initial: s.query,
                    onChanged: s.setQuery,
                  ),
                ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: widget.onOpenTrips,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPanel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CustomPaint(painter: MiniMapPainter()),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your trips',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tripCount == 0
                                    ? 'Nothing saved yet. Pick a place to start.'
                                    : '$tripCount saved. Tap to view them.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: kMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CategoryChips(selected: s.mood, onSelected: s.setMood),
              const SizedBox(height: 8),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyBox(
                    icon: Icons.travel_explore,
                    title: 'No places match that',
                    message: 'Try another word or a different category.',
                    actionLabel: 'Clear filters',
                    onAction: s.clearFilters,
                  ),
                )
              else ...[
                SectionTitle('Recommendation', onViewAll: widget.onViewAll),
                SizedBox(
                  height: 276,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    itemCount: top.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => SizedBox(
                      width: 232,
                      child: DestinationCard(
                        p: top[i],
                        heroTag: 'rec-${top[i].id}',
                        saved: s.trips.containsKey(top[i].id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SectionTitle('Nearby from you', onViewAll: widget.onViewAll),
                for (final p in near.take(4))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: DestinationCard(
                      p: p,
                      wide: true,
                      heroTag: 'near-${p.id}',
                      saved: s.trips.containsKey(p.id),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
