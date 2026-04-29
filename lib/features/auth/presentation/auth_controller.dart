import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/storage/session_storage.dart';
import '../data/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AppSession?> {
  @override
  Future<AppSession?> build() async {
    return ref.read(sessionStorageProvider).loadSession();
  }

  Future<AppSession> login({
    required String phone,
    required String password,
    required bool isAdmin,
  }) async {
    state = const AsyncLoading();
    final session = await ref
        .read(authRepositoryProvider)
        .login(phone: phone, password: password, isAdmin: isAdmin);
    await ref.read(sessionStorageProvider).saveSession(session);
    state = AsyncData(session);
    return session;
  }

  Future<void> completeSession(AppSession session) async {
    await ref.read(sessionStorageProvider).saveSession(session);
    state = AsyncData(session);
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final profile = await ref.read(authRepositoryProvider).fetchProfile();
    final updated = AppSession(token: current.token, user: profile);
    await ref.read(sessionStorageProvider).saveSession(updated);
    state = AsyncData(updated);
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final profile = await ref
        .read(authRepositoryProvider)
        .updateProfile(payload);
    final updated = AppSession(token: current.token, user: profile);
    await ref.read(sessionStorageProvider).saveSession(updated);
    state = AsyncData(updated);
  }

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}
