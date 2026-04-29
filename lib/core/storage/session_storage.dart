import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_models.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage());

class SessionStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _sessionKey = 'house_rent_session';
  static const _onboardingKey = 'house_rent_onboarding_seen';

  Future<void> saveSession(AppSession session) async {
    await _secureStorage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<AppSession?> loadSession() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return AppSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _sessionKey);
  }

  Future<void> markOnboardingSeen() async {
    await _secureStorage.write(key: _onboardingKey, value: 'true');
  }

  Future<bool> isOnboardingSeen() async {
    return (await _secureStorage.read(key: _onboardingKey)) == 'true';
  }
}
