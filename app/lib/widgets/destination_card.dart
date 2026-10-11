import 'package:flutter/material.dart';

import '../models/place.dart';
import '../screens/detail_screen.dart';
import '../theme.dart';
import '../util.dart';
import 'common.dart';
import 'photo_box.dart';

/// Photo card with name, rating and location. With [wide] true it is a
/// full-width card (photo on top, fixed height) for vertical lists.
class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.p,
    required this.heroTag,
    this.saved = false,
    this.wide = false,
  });

  final Place p;
  final String heroTag;
  final bool saved;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final photo = Stack(
      children: [
        Positioned.fill(
          child: Hero(tag: heroTag, child: PhotoBox(p: p, radius: 18)),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.fade(0.85),
            ),
            child: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border_rounded,
              size: 18,
              color: saved ? kPrimary : kInk,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '${p.name}, ${p.country}, rated ${p.rating}',
      child: GestureDetector(
        onTap: () => openPlace(context, p, heroTag),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: cardDecoration(),
          child: Column(
            mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide) SizedBox(height: 150, child: photo) else Expanded(child: photo),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Rating(p.rating),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: LocationLine(p.country)),
                  if (wide)
                    Text(
                      '${fmtHours(p.flightHours)} flight',
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                ],
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
