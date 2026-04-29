import 'package:flutter/foundation.dart';

class AppConfig {
  static const _apiOverride = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) {
      return _apiOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api/v1';
      default:
        return 'http://localhost:5000/api/v1';
    }
  }

  static String get appName => 'HouseRent Pro';
}
