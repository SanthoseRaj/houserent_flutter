import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentRepository(apiClient);
});

class CheckoutSessionResult {
  const CheckoutSessionResult({
    required this.paymentId,
    this.sessionId,
    this.checkoutUrl,
  });

  final String paymentId;
  final String? sessionId;
  final String? checkoutUrl;
}

class PaymentRepository {
  const PaymentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CheckoutSessionResult> createCheckout({
    required String propertyId,
    required num amount,
    required String month,
  }) async {
    final response = await _apiClient.post(
      '/payments/checkout-session',
      data: {
        'propertyId': propertyId,
        'amount': amount,
        'month': month,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return CheckoutSessionResult(
      paymentId: (data['paymentId'] ?? data['payment']?['_id'] ?? '').toString(),
      sessionId: data['sessionId']?.toString(),
      checkoutUrl: data['checkoutUrl']?.toString(),
    );
  }

  Future<void> verifySession(String sessionId) async {
    await _apiClient.get('/payments/verify-session/$sessionId');
  }

  Future<List<PaymentItem>> fetchMyPayments() async {
    final response = await _apiClient.get('/payments/mine');
    return (response['data'] as List<dynamic>).map((e) => PaymentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PaymentItem>> fetchAdminPayments() async {
    final response = await _apiClient.get('/payments');
    return (response['data'] as List<dynamic>).map((e) => PaymentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String?> fetchReceiptUrl(String paymentId) async {
    final response = await _apiClient.get('/payments/receipt/$paymentId');
    return (response['data'] as Map<String, dynamic>)['receiptUrl']?.toString();
  }
}
