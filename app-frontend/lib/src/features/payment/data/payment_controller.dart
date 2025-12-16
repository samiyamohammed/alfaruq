import 'package:al_faruk_app/src/features/payment/data/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(ref);
});

class PaymentController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PaymentController(this._ref) : super(const AsyncData(null));

  Future<void> buyContent(String contentId) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(paymentRepositoryProvider);

      // 1. Get the Chapa URL
      final String checkoutUrl =
          await repo.initiatePurchase(contentId: contentId);

      if (checkoutUrl.isEmpty) {
        throw "Invalid payment URL received";
      }

      // 2. Launch the URL
      final Uri uri = Uri.parse(checkoutUrl);

      // FIX: We removed the 'await canLaunchUrl(uri)' check because it fails
      // on Android 11+ without specific manifest changes.
      // launchUrl will throw or return false if it fails anyway.
      try {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens Chrome/Safari
        );

        if (!launched) {
          throw "Could not open the browser.";
        }

        // Success (user is now in the browser)
        state = const AsyncData(null);
      } catch (e) {
        throw "Could not launch payment page. Please check your browser settings.";
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
