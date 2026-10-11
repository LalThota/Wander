import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/tourist_place.dart';
import '../services/maps.dart';
import '../theme.dart';
import 'section_card.dart';

/// Interactive map section displaying destination location, nearby points of interest pins,
/// and instant redirection into Google Maps or native Maps app.
class MapSectionCard extends StatefulWidget {
  const MapSectionCard({
    super.key,
    required this.destination,
    required this.places,
    this.initiallyExpanded = true,
  });

  final Place destination;
  final List<TouristPlace>? places;
  final bool initiallyExpanded;

  @override
  State<MapSectionCard> createState() => _MapSectionCardState();
}

class _MapSectionCardState extends State<MapSectionCard> {
  TouristPlace? _selectedPlace;

  Place get p => widget.destination;

  // Approximate default coordinates if not set by API
  double get _centerLat => p.lat ?? _fallbackLat(p.id);
  double get _centerLng => p.lng ?? _fallbackLng(p.id);

  static double _fallbackLat(String id) {
    switch (id) {
      case 'bali':
        return -8.5069;
      case 'santorini':
        return 36.4167;
      case 'maldives':
        return 4.1755;
      case 'kyoto':
        return 34.9858;
      case 'jaipur':
        return 26.9124;
      case 'cusco':
        return -13.5320;
      case 'banff':
        return 51.1784;
      case 'ladakh':
        return 34.1526;
      default:
        return 20.0;
    }
  }

  static double _fallbackLng(String id) {
    switch (id) {
      case 'bali':
        return 115.2625;
      case 'santorini':
        return 25.4326;
      case 'maldives':
        return 73.5093;
      case 'kyoto':
        return 135.7588;
      case 'jaipur':
        return 75.7873;
      case 'cusco':
        return -71.9675;
      case 'banff':
        return -115.5708;
      case 'ladakh':
        return 77.5771;
      default:
        return 78.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.places ?? const <TouristPlace>[];

    return SectionCard(
      title: 'Interactive Map & Location',
      icon: Icons.map_rounded,
      initiallyExpanded: widget.initiallyExpanded,
      summary: '${p.name}, ${p.country} • ${_centerLat.toStringAsFixed(3)}°, ${_centerLng.toStringAsFixed(3)}°',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual stylized interactive map viewport
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: kLine),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapW = constraints.maxWidth;
                  final mapH = constraints.maxHeight;
                  return Stack(
                    children: [
                      // Stylized map painter with geographical grids and roads
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapCanvasPainter(
                            centerLat: _centerLat,
                            centerLng: _centerLng,
                            places: places,
                          ),
                        ),
                      ),

                      // Destination center marker (Pulse radar)
                      Positioned(
                        top: mapH * 0.5 - 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimary.withAlpha(120),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pins for nearby places
                      ..._buildPins(places, mapW, mapH),

                  // Overlay badge with coordinates and map mode
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location, size: 13, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Text(
                            '${_centerLat.toStringAsFixed(4)}° N, ${_centerLng.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap place hint on map
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'Tap pin to view',
                            style: TextStyle(color: Colors.white70, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),

          // If a pin is selected, show its detail card
          if (_selectedPlace != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimary.withAlpha(80)),
              ),
              child: Row(
                children: [
                  if (_selectedPlace!.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _selectedPlace!.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.place, size: 30, color: kPrimary),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(categoryIcon(_selectedPlace!.category), color: kPrimary),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlace!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedPlace!.distanceLabel} away • ${_selectedPlace!.category}',
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => openMap(context, _selectedPlace!.mapUrl),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Primary Navigation Button: Open in Google Maps / Native Maps App
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => openLocationInMap(
                context,
                lat: _centerLat,
                lng: _centerLng,
                label: '${p.name}, ${p.country}',
              ),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: Text(
                'Open ${p.name} in Maps App',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPins(List<TouristPlace> places, double mapW, double mapH) {
    final list = <Widget>[];
    final count = math.min(places.length, 6);

    for (var i = 0; i < count; i++) {
      final tp = places[i];
      // Distribute pins pleasantly around the center based on index and distance
      final angle = (i * 2 * math.pi / count) + 0.4;
      final dist = 55.0 + (i % 3) * 25.0;
      final dx = math.cos(angle) * dist;
      final dy = math.sin(angle) * (dist * 0.7);

      final isSelected = _selectedPlace?.id == tp.id;
      final posX = (mapW * 0.5 + dx - 35).clamp(10.0, math.max(10.0, mapW - 85.0)).toDouble();
      final posY = (mapH * 0.5 + dy - 16).clamp(38.0, math.max(38.0, mapH - 36.0)).toDouble();

      list.add(
        Positioned(
          top: posY,
          left: posX,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlace = isSelected ? null : tp;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF43F5E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF38BDF8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isSelected ? 90 : 50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcon(tp.category),
                    size: 13,
                    color: isSelected ? Colors.white : kPrimary,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Text(
                      tp.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }
}

/// Stylized map canvas rendering realistic grid lines, terrain contour circles, and route paths.
class _MapCanvasPainter extends CustomPainter {
  _MapCanvasPainter({
    required this.centerLat,
    required this.centerLng,
    required this.places,
  });

  final double centerLat;
  final double centerLng;
  final List<TouristPlace> places;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark sleek map background
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle coordinate grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    for (double x = 0; x < w; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Topographic contours / radius circles
    final center = Offset(w * 0.5, h * 0.5);
    final ringPaint = Paint()
      ..color = const Color(0xFF38BDF8).withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final radius in [40.0, 75.0, 110.0, 150.0]) {
      canvas.drawCircle(center, radius, ringPaint);
    }

    // Stylized travel road network
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = Path()
      ..moveTo(0, h * 0.3)
      ..quadraticBezierTo(w * 0.3, h * 0.45, center.dx, center.dy)
      ..quadraticBezierTo(w * 0.7, h * 0.55, w, h * 0.75);
    canvas.drawPath(path, roadPaint);

    final road2 = Path()
      ..moveTo(w * 0.2, 0)
      ..quadraticBezierTo(w * 0.4, h * 0.3, center.dx, center.dy)
      ..quadraticBezierTo(w * 0.6, h * 0.8, w * 0.8, h);
    canvas.drawPath(road2, roadPaint);

    // Radiating radar waves around destination center
    final radarPaint = Paint()
      ..color = const Color(0xFF38BDF8).withAlpha(35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, radarPaint);
  }

  @override
  bool shouldRepaint(_MapCanvasPainter old) => false;
}
