import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/multipart_upload.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient);
});

class AdminRepository {
  const AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> fetchDashboard() async {
    final response = await _apiClient.get('/admin/dashboard');
    return DashboardSummary.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AppUser>> fetchUsers() async {
    final response = await _apiClient.get('/admin/users');
    return (response['data'] as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    await _apiClient.post('/admin/users', data: payload);
  }

  Future<void> updateUserStatus(String id, String status) async {
    await _apiClient.patch('/admin/users/$id/status', data: {'status': status});
  }

  Future<List<Map<String, dynamic>>> fetchPaymentReport() async {
    final response = await _apiClient.get('/admin/reports/payments');
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> uploadAgreement({
    required String userId,
    required String propertyId,
    required String title,
    required String startDate,
    required String endDate,
    required num rent,
    PlatformFile? file,
  }) async {
    final formData = FormData.fromMap({
      'userId': userId,
      'propertyId': propertyId,
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'rent': rent,
      if (file != null) 'file': await platformFileToMultipartFile(file),
    });
    await _apiClient.postForm('/agreements', formData);
  }

  Future<void> updateComplaint(
    String id,
    String status,
    String adminReply,
  ) async {
    await _apiClient.patch(
      '/complaints/$id',
      data: {'status': status, 'adminReply': adminReply},
    );
  }
}
