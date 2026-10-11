import 'package:flutter/foundation.dart';

/// Deployed backend, used by release builds.
const _production = 'https://wander-app-xp36.onrender.com';

/// Override at build or run time:
///   flutter run --dart-define=API_URL=http://10.161.197.7:8001
///   flutter build apk --dart-define=API_URL=http://10.161.197.7:8001
const _override = String.fromEnvironment('API_URL');

String? _customServerUrl;

void setCustomServerUrl(String? url) {
  _customServerUrl = url?.trim().isEmpty == true ? null : url?.trim();
}

String get apiBase {
  if (_customServerUrl != null && _customServerUrl!.isNotEmpty) {
    return _customServerUrl!;
  }
  if (_override.isNotEmpty) return _override;
  // Release builds default to production if defined, else local Wi-Fi / localhost
  if (kReleaseMode) {
    // If not overridden, default to local machine IP so APK works out of the box
    return 'http://10.161.197.7:8001';
  }
  // Debug and profile builds default to local FastAPI server.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8001';
  }
  return 'http://localhost:8001';
}
