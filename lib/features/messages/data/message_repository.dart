import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MessageRepository(apiClient);
});

class MessageRepository {
  const MessageRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ChatThread>> fetchThreads() async {
    final response = await _apiClient.get('/messages/threads');
    return (response['data'] as List<dynamic>).map((e) => ChatThread.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> fetchThread(String participantId) async {
    final response = await _apiClient.get('/messages/thread/$participantId');
    return (response['data'] as List<dynamic>).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage({
    required String message,
    String? receiverId,
    String? propertyId,
  }) async {
    final payload = <String, dynamic>{
      'message': message,
    };
    if (receiverId != null) {
      payload['receiverId'] = receiverId;
    }
    if (propertyId != null) {
      payload['propertyId'] = propertyId;
    }

    await _apiClient.post(
      '/messages',
      data: payload,
    );
  }
}
