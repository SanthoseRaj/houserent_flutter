import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/multipart_upload.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApplicationRepository(apiClient);
});

class UploadableDocument {
  const UploadableDocument({
    required this.label,
    required this.file,
  });

  final String label;
  final PlatformFile file;
}

class ApplicationRepository {
  const ApplicationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<String>> uploadDocuments(List<UploadableDocument> documents) async {
    final formData = FormData();
    formData.fields.add(
      MapEntry(
        'labels',
        '["${documents.map((e) => e.label.replaceAll('"', '\\"')).join('","')}"]',
      ),
    );

    for (final document in documents) {
      formData.files.add(
        MapEntry(
          'files',
          await platformFileToMultipartFile(document.file),
        ),
      );
    }

    final response = await _apiClient.postForm('/uploads/documents', formData);
    return (response['data'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> submitApplication({
    required String propertyId,
    required Map<String, dynamic> personalDetails,
    required String remarks,
    required List<String> documentIds,
  }) async {
    await _apiClient.post(
      '/applications',
      data: {
        'propertyId': propertyId,
        'personalDetails': personalDetails,
        'remarks': remarks,
        'documentIds': documentIds,
      },
    );
  }

  Future<List<RentalApplicationItem>> fetchMyApplications() async {
    final response = await _apiClient.get('/applications/mine');
    return (response['data'] as List<dynamic>)
        .map((e) => RentalApplicationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RentalApplicationItem>> fetchAdminApplications() async {
    final response = await _apiClient.get('/applications');
    return (response['data'] as List<dynamic>)
        .map((e) => RentalApplicationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RentalApplicationItem> fetchApplication(String id) async {
    final response = await _apiClient.get('/applications/$id');
    return RentalApplicationItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> updateApplicationStatus({
    required String id,
    required String status,
    String? adminRemarks,
    bool assignTenant = false,
  }) async {
    await _apiClient.patch(
      '/applications/$id/status',
      data: {
        'status': status,
        'adminRemarks': adminRemarks,
        'assignTenant': assignTenant,
      },
    );
  }
}
