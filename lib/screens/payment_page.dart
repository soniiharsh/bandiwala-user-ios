// ✅ COMPLETE PaymentPage.dart - Multi-Vendor Status Support + Fixed Layout
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_store.dart';
import 'payment_success_page.dart';

const kBandiwalaYellow = Color(0xFFFFC107);
const kWhite = Color(0xFFFFFFFF);
const kBorderGrey = Color(0xFFE5E7EB);
const kTextGrey = Color(0xFF6B7280);

class PaymentPage extends StatefulWidget {
  final double amount;
  final String? deliveryAddress;

  const PaymentPage({
    super.key,
    required this.amount,
    this.deliveryAddress,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  double get totalPayable => widget.amount * 1.05 + 30;

  void _openCheckout() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final options = {
      'key': 'rzp_test_Ry7KzKrnhBoqUK',
      'amount': (widget.amount * 100).toInt(),
      'name': 'Bandiwala',
      'description': 'Street food delivery',
      'prefill': {'contact': '9999999999', 'email': 'customer@example.com'},
      'external': {'wallets': ['PAYTM']},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed to initialize')),
        );
      }
    }
  }

  Future<String> _createOrderInFirestore(String paymentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String customerPhone = user?.phoneNumber ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final String deliveryAddress = widget.deliveryAddress ?? 'Not provided';
      final String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> orderData = {
        'orderId': orderId,
        'paymentId': paymentId,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'status': 'confirmed',
        'timestamp': FieldValue.serverTimestamp(),
        'itemTotal': widget.amount,
        'deliveryCharge': 30.0,
        'tax': widget.amount * 0.05,
        'grandTotal': totalPayable,
        'itemsByVendor': <String, dynamic>{},
      };

      // Build nested map with vendor-specific status
      final Map<String, dynamic> cartCopy = {};
      for (final entry in cartStore.cartByVendor.entries) {
        final vendorId = entry.key;
        final itemsCopy = List<Map<String, dynamic>>.from(
            entry.value.items.map((item) => {
              'itemId': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            })
        );

        // Calculate vendor-specific subtotal
        double vendorSubtotal = 0;
        for (final item in entry.value.items) {
          vendorSubtotal += item.price * item.quantity;
        }

        cartCopy[vendorId] = {
          'vendorName': entry.value.vendorName,
          'items': itemsCopy,
          'status': 'pending', // ✅ Individual vendor status
          'vendorSubtotal': vendorSubtotal,
          'orderReceivedAt': FieldValue.serverTimestamp(),
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        };
      }
      orderData['itemsByVendor'] = cartCopy;

      await FirebaseFirestore.instance.collection('orders').add(orderData);
      debugPrint('✅ Order created: $orderId with ${cartCopy.length} vendors');
      return orderId;
    } catch (e) {
      debugPrint('❌ Firestore error: $e');
      return 'order_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _clearCartSafely() {
    final vendorIds = List<String>.from(cartStore.cartByVendor.keys);
    for (final vendorId in vendorIds) {
      final vendorCart = cartStore.cartByVendor[vendorId];
      if (vendorCart != null) {
        final itemIds = List<String>.from(vendorCart.items.map((item) => item.id));
        for (final itemId in itemIds) {
          cartStore.updateQuantity(vendorId: vendorId, itemId: itemId, delta: -999);
        }
      }
    }
    debugPrint('🛒 Cart cleared safely');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('🚀=== PAYMENT SUCCESS TRIGGERED ===');
    final String paymentId = response.paymentId ?? '';

    if (paymentId.isEmpty) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment ID'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final String orderId = await _createOrderInFirestore(paymentId);
      _clearCartSafely();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                paymentId: paymentId,
                amount: totalPayable,
                orderId: orderId,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Wallet: ${response.walletName}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: kWhite,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: ColoredBox(color: kBorderGrey, child: SizedBox(height: 1)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _compactSummaryCard(),
                const SizedBox(height: 12),
                if (widget.deliveryAddress != null && widget.deliveryAddress!.isNotEmpty)
                  _compactAddressCard(),
                const SizedBox(height: 12),
                _compactPaymentMethod(),
              ],
            ),
          ),
          // ✅ Bottom section fixed at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              border: Border(top: BorderSide(color: kBorderGrey, width: 1)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _compactSecureBadge(),
                  const SizedBox(height: 12),
                  _compactPayButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSummaryCard() {
    final taxAmount = widget.amount * 0.05;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: kBandiwalaYellow, size: 18),
              const SizedBox(width: 8),
              const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _compactRow('Items', '₹${widget.amount.toStringAsFixed(0)}'),
          _compactRow('Delivery', '₹30'),
          _compactRow('Tax (5%)', '₹${taxAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Container(height: 1, color: kBorderGrey),
          const SizedBox(height: 8),
          _compactRow('Total', '₹${totalPayable.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _compactAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderGrey, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBandiwalaYellow.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.location_on, color: kBandiwalaYellow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  widget.deliveryAddress!,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactPaymentMethod() {
    return GestureDetector(
      onTap: _isProcessing ? null : _openCheckout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderGrey, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBandiwalaYellow.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.credit_card, color: kBandiwalaYellow, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Card/UPI/Wallet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    _isProcessing ? 'Processing...' : 'Secure payment',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              _isProcessing ? Icons.hourglass_empty : Icons.arrow_forward_ios,
              color: _isProcessing ? Colors.grey : kBandiwalaYellow,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactSecureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBandiwalaYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBandiwalaYellow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 14, color: kBandiwalaYellow),
          const SizedBox(width: 6),
          Text(
            'Secured by Razorpay',
            style: TextStyle(fontSize: 11, color: kBandiwalaYellow, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _compactPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _openCheckout,
        icon: _isProcessing
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
        )
            : const Icon(Icons.payment, size: 18, color: Colors.black),
        label: Text(
          _isProcessing ? 'Processing...' : 'Pay ₹${totalPayable.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBandiwalaYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          disabledBackgroundColor: kBandiwalaYellow.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _compactRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black87 : kTextGrey)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? kBandiwalaYellow : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
