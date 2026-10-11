import 'package:flutter/material.dart';

import '../models/place.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_card.dart';
import '../widgets/search_and_chips.dart';

/// "View all": every destination in a grid with search, category and sort.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _sort = 'rating';

  static const _sorts = {
    'rating': 'Top rated',
    'near': 'Nearest',
    'price': 'Lowest daily cost',
  };

  List<Place> _sorted(List<Place> list) {
    final out = [...list];
    switch (_sort) {
      case 'near':
        out.sort((a, b) => a.flightHours.compareTo(b.flightHours));
      case 'price':
        out.sort((a, b) => a.perDay.compareTo(b.perDay));
      default:
        out.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.loading && s.places.isEmpty) return const LoadingBox();
    if (s.error != null && s.places.isEmpty) {
      return ErrorBox(message: s.error!, onRetry: s.load);
    }
    final list = _sorted(s.visible);

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Text(
                  'Explore',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SearchBox(
                  key: ValueKey(s.filterEpoch),
                  initial: s.query,
                  onChanged: s.setQuery,
                ),
              ),
              const SizedBox(height: 10),
              CategoryChips(selected: s.mood, onSelected: s.setMood, includeAll: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Row(
                  children: [
                    Text(
                      '${list.length} places',
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Sort destinations',
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (_) => [
                        for (final e in _sorts.entries)
                          PopupMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_vert_rounded, size: 18, color: kPrimary),
                          const SizedBox(width: 4),
                          Text(
                            _sorts[_sort]!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? EmptyBox(
                        icon: Icons.travel_explore,
                        title: 'No places match that',
                        message: 'Try another word or a different category.',
                        actionLabel: 'Clear filters',
                        onAction: s.clearFilters,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 120),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => DestinationCard(
                          p: list[i],
                          heroTag: 'grid-${list[i].id}',
                          saved: s.trips.containsKey(list[i].id),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
