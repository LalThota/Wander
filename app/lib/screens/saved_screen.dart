import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/place.dart';
import '../models/travel.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/photo_box.dart';
import 'detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.onBrowse});

  /// Jumps back to Home from the empty state.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    final items = <(Trip, Place)>[];
    for (final t in s.trips.values) {
      final p = s.placeById(t.destinationId);
      if (p != null) items.add((t, p));
    }
    items.sort((a, b) => b.$1.updatedAt.compareTo(a.$1.updatedAt));

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: items.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title(),
                    Expanded(
                      child: EmptyBox(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No saved trips yet',
                        message: 'Plan a trip and tap Save trip. It will show up here.',
                        actionLabel: 'Browse places',
                        onAction: onBrowse,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: items.length + 1,
                  itemBuilder: (context, k) {
                    if (k == 0) return const _Title(pad: false);
                    final (trip, place) = items[k - 1];
                    return _TripCard(
                      trip: trip,
                      place: place,
                      onOpen: () => openPlace(context, place, 'saved-${place.id}'),
                      onRemove: () => _remove(context, s, place),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, AppState s, Place p) async {
    final err = await s.removeTrip(p.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Removed')));
  }
}

class _Title extends StatelessWidget {
  const _Title({this.pad = true});
  final bool pad;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(pad ? 24 : 0, 20, 24, 16),
        child: const Text(
          'Saved trips',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.place,
    required this.onOpen,
    required this.onRemove,
  });

  final Trip trip;
  final Place place;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasBudget = trip.budget != null;
    final parts = [
      for (final c in budgetCategories)
        if ((trip.breakdown[c.key] ?? 0) > 0) (c, trip.breakdown[c.key]!),
    ];
    final mode = trip.travelMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: PhotoBox(p: place, radius: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${place.name} trip',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${trip.days} days, ${place.country}',
                            style: const TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove trip',
                      icon: const Icon(Icons.delete_outline_rounded, color: kMuted),
                      onPressed: onRemove,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Block(
                  title: hasBudget ? 'Total budget' : 'Estimated cost',
                  child: Text(
                    inr(hasBudget ? trip.budget! : trip.total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
                if (parts.isNotEmpty)
                  _Block(
                    title: 'Budget breakdown',
                    child: Column(
                      children: [
                        for (final e in parts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(e.$1.icon, size: 16, color: kPrimary),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 108,
                                  child: Text(
                                    e.$1.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: clampD(e.$2 / (trip.budget ?? e.$2), 0, 1),
                                      minHeight: 6,
                                      color: kPrimary,
                                      backgroundColor: kLine,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  inr(e.$2),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                if (mode != null)
                  _Block(
                    title: 'Travel',
                    child: Row(
                      children: [
                        Icon(modeIcon(mode), size: 20, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(modeLabel(mode), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '${trip.travelCost != null ? inr(trip.travelCost!) : '-'} estimated'
                            '${trip.travelers > 1 ? ' for ${trip.travelers}' : ''}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                _Block(
                  title: 'Required items',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final item in place.pack)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trip.packed.contains(item)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: trip.packed.contains(item) ? kGood : kMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: trip.packed.contains(item) ? kInk : kMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (trip.places.isNotEmpty)
                  _Block(
                    title: 'Nearby places',
                    last: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final p in trip.places)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 15, color: kPrimary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(p.name, style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.last = false});
  final String title;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: last ? 0 : 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}
