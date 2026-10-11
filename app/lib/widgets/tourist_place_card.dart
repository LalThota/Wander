import 'package:flutter/material.dart';

import '../models/tourist_place.dart';
import '../services/maps.dart';
import '../theme.dart';

/// One nearby attraction: picture, distance, category, short text and actions.
class TouristPlaceCard extends StatelessWidget {
  const TouristPlaceCard({
    super.key,
    required this.place,
    required this.added,
    required this.onToggle,
  });

  final TouristPlace place;
  final bool added;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: added ? kPrimary : kLine, width: added ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(place),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 15, color: kPrimary),
                        const SizedBox(width: 2),
                        Text(
                          place.distanceLabel,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: kMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => openMap(context, place.mapUrl),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('View on map'),
                style: TextButton.styleFrom(foregroundColor: kPrimary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  added ? Icons.check_circle : Icons.add_circle_outline,
                  size: 18,
                ),
                label: Text(added ? 'Added' : 'Add to trip'),
                style: TextButton.styleFrom(
                  foregroundColor: added ? kGood : kInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.place);
  final TouristPlace place;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: kPrimarySoft,
      alignment: Alignment.center,
      child: Icon(categoryIcon(place.category), size: 30, color: kPrimary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 78,
        height: 78,
        child: place.imageUrl == null
            ? fallback
            : Image.network(
                place.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
