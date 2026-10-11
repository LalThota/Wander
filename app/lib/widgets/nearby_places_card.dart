import 'package:flutter/material.dart';

import '../models/tourist_place.dart';
import '../theme.dart';
import 'common.dart';
import 'section_card.dart';
import 'tourist_place_card.dart';

/// Nearby tourist places with sort and category filters.
class NearbyPlacesCard extends StatelessWidget {
  const NearbyPlacesCard({
    super.key,
    required this.places,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.sort,
    required this.onSort,
    required this.category,
    required this.onCategory,
    required this.selectedIds,
    required this.onToggle,
    required this.onFirstExpand,
    required this.initiallyExpanded,
  });

  final List<TouristPlace>? places;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final String sort;
  final ValueChanged<String> onSort;
  final String? category;
  final ValueChanged<String?> onCategory;
  final Set<String> selectedIds;
  final ValueChanged<TouristPlace> onToggle;
  final VoidCallback onFirstExpand;
  final bool initiallyExpanded;

  static const _sorts = {
    'nearest': 'Nearest',
    'popular': 'Popular',
    'category': 'Category',
  };

  @override
  Widget build(BuildContext context) {
    final count = places?.length;
    return SectionCard(
      title: 'Nearby places',
      icon: Icons.place_outlined,
      initiallyExpanded: initiallyExpanded,
      onFirstExpand: onFirstExpand,
      summary: count == null
          ? 'Things to see around here'
          : '$count places, ${selectedIds.length} added to your trip',
      child: _body(),
    );
  }

  Widget _body() {
    if (places == null) {
      if (error != null) return ErrorBox(message: error!, onRetry: onRetry);
      if (loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LoadingBox(message: 'Finding places nearby...'),
        );
      }
      return const SizedBox.shrink();
    }
    final all = places!;
    if (all.isEmpty) {
      return const EmptyBox(
        icon: Icons.travel_explore,
        title: 'No places yet',
        message: 'We have no nearby places for this destination yet.',
      );
    }

    final cats = <String>[];
    for (final p in all) {
      if (!cats.contains(p.category)) cats.add(p.category);
    }
    final view = sortPlaces(
      category == null ? all : all.where((p) => p.category == category).toList(),
      sort,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Sort by', style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'Sort places',
              initialValue: sort,
              onSelected: onSort,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (_) => [
                for (final e in _sorts.entries)
                  PopupMenuItem(value: e.key, child: Text(e.value)),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPanel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sorts[sort] ?? 'Nearest',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Straight-line distance',
              style: TextStyle(fontSize: 11.5, color: kMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip('All', category == null, () => onCategory(null)),
              for (final c in cats) _chip(c, category == c, () => onCategory(c)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final p in view)
          TouristPlaceCard(
            place: p,
            added: selectedIds.contains(p.id),
            onToggle: () => onToggle(p),
          ),
      ],
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: on ? kPrimary : kLine),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : kInk,
              ),
            ),
          ),
        ),
      );
}
