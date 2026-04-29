import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class OtpDispatchResult {
  const OtpDispatchResult({
    required this.email,
    required this.accountType,
    this.devOtp,
  });

  final String email;
  final String accountType;
  final String? devOtp;
}

class AuthRepository {
  const AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AppSession> login({
    required String phone,
    required String password,
    required bool isAdmin,
  }) async {
    final response = await _apiClient.post(
      isAdmin ? '/auth/admin/login' : '/auth/user/login',
      data: {'phone': phone.trim(), 'password': password},
    );

    return AppSession.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AppSession> signUp(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/auth/user/signup', data: payload);
    return AppSession.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AppSession> verifyOtp({
    required String email,
    required String otp,
    required String accountType,
  }) async {
    final response = await _apiClient.post(
      '/auth/verify-otp',
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'accountType': accountType,
      },
    );

    return AppSession.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<OtpDispatchResult> resendOtp({
    required String email,
    required String accountType,
    required String purpose,
  }) async {
    final response = await _apiClient.post(
      '/auth/resend-otp',
      data: {
        'email': email.trim(),
        'accountType': accountType,
        'purpose': purpose,
      },
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return OtpDispatchResult(
      email: email,
      accountType: accountType,
      devOtp: data['devOtp']?.toString(),
    );
  }

  Future<OtpDispatchResult> forgotPassword({
    required String email,
    required String accountType,
  }) async {
    final response = await _apiClient.post(
      '/auth/forgot-password',
      data: {'email': email.trim(), 'accountType': accountType},
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return OtpDispatchResult(
      email: email,
      accountType: accountType,
      devOtp: data['devOtp']?.toString(),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String accountType,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
        'accountType': accountType,
      },
    );
  }

  Future<AppUser> fetchProfile() async {
    final response = await _apiClient.get('/auth/me');
    return AppUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile(Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/auth/profile', data: payload);
    return AppUser.fromJson(response['data'] as Map<String, dynamic>);
  }
}
