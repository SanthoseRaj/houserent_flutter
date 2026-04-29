import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

class NotificationRepository {
  const NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NotificationItem>> fetchNotifications() async {
    final response = await _apiClient.get('/notifications');
    return (response['data'] as List<dynamic>)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String audience,
  }) async {
    await _apiClient.post(
      '/notifications/announcement',
      data: {
        'title': title,
        'body': body,
        'audience': audience,
      },
    );
  }
}
