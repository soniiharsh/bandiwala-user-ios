import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../providers/orders_provider.dart';

const _razorpayKey = 'rzp_live_SIEw0ZGDGbPgTd';

class PaymentService {
  final Razorpay _razorpay = Razorpay();

  /// Called with the Firestore doc ID on success.
  final void Function(String orderId) onSuccess;

  /// Called with an error message on failure.
  final void Function(String message) onError;

  /// Supplies the current order snapshot to build on payment success.
  final AppOrder Function() buildOrder;

  PaymentService({
    required this.onSuccess,
    required this.onError,
    required this.buildOrder,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse r) => debugPrint('Wallet: ${r.walletName}'),
    );
  }

  void dispose() => _razorpay.clear();

  // ── Online payment ────────────────────────────────────────────────────────

  void openRazorpay(double amount) {
    final options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'BandiWala',
      'description': 'Street food delivery',
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': 'customer@bandiwala.in',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      onError('Payment failed to initialize');
    }
  }

  // ── COD ───────────────────────────────────────────────────────────────────

  Future<void> placeCodOrder() async {
    final order = buildOrder().copyWith(
      paymentId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
      paymentMethod: 'cod',
      status: OrderStatus.orderCreated,
    );
    try {
      final docId = await placeOrder(order);
      onSuccess(docId);
    } catch (e) {
      onError('Failed to place order: $e');
    }
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _handleSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    if (paymentId.isEmpty) {
      onError('Invalid payment response');
      return;
    }
    final order = buildOrder().copyWith(
      paymentId: paymentId,
      paymentMethod: 'online',
      status: OrderStatus.orderCreated,
    );
    try {
      final docId = await placeOrder(order);
      onSuccess(docId);
    } catch (e) {
      onError('Order error: $e');
    }
  }

  void _handleError(PaymentFailureResponse response) {
    onError(response.message ?? 'Unknown error');
  }
}
