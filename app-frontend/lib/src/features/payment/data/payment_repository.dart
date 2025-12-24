import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentRepository(dio: dio);
});

class PaymentRepository {
  final Dio _dio;

  PaymentRepository({required Dio dio}) : _dio = dio;

  Future<String> initiatePurchase({
    required String contentId,
    required int durationDays, // UPDATED
  }) async {
    try {
      final response = await _dio.post(
        '/purchase/initiate',
        data: {
          'contentId': contentId,
          'durationDays': durationDays,
        },
      );

      if (response.statusCode == 201) {
        return response.data['checkoutUrl'];
      } else {
        throw "Failed to initiate purchase";
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        throw e.response!.data['message'] ?? "Payment Error";
      }
      throw "Connection Error";
    } catch (e) {
      throw "Unexpected Error: $e";
    }
  }
}
