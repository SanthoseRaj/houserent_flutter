import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

class ProfileRepository {
  const ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ComplaintItem>> fetchComplaints() async {
    final response = await _apiClient.get('/complaints');
    return (response['data'] as List<dynamic>)
        .map((e) => ComplaintItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createComplaint({
    required String propertyId,
    required String subject,
    required String description,
  }) async {
    await _apiClient.post(
      '/complaints',
      data: {
        'propertyId': propertyId,
        'subject': subject,
        'description': description,
      },
    );
  }

  Future<List<AgreementItem>> fetchAgreements() async {
    final response = await _apiClient.get('/agreements');
    return (response['data'] as List<dynamic>)
        .map((e) => AgreementItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
