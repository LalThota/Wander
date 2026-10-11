import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a Google Maps or native Maps app link with robust multi-platform fallbacks.
Future<void> openMap(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  var opened = false;
  // Strategy 1: Launch in external maps application
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }

  // Strategy 2: Fallback to platform default / in-browser
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
  }

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open the map. Please try again."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Directly opens a specific latitude/longitude location in the Maps app.
Future<void> openLocationInMap(
  BuildContext context, {
  required double lat,
  required double lng,
  required String label,
}) async {
  final cleanLabel = Uri.encodeComponent(label);

  // Platform specific schemes for immediate native Maps app routing:
  Uri? primaryUri;
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid) {
        // Android geo intent directly invokes Google Maps / native navigation
        primaryUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($cleanLabel)');
      } else if (Platform.isIOS) {
        // iOS Apple Maps URL
        primaryUri = Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$cleanLabel');
      }
    } catch (_) {}
  }

  // Universal web & mobile fallback URL:
  final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  if (primaryUri != null) {
    try {
      if (await canLaunchUrl(primaryUri)) {
        final ok = await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}
  }

  await openMap(context, fallbackUrl);
}
