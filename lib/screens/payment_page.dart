// payment_page.dart

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
const kBgGrey = Color(0xFFF9FAFB);

// ─── PaymentPage ──────────────────────────────────────────────────────────────

class PaymentPage extends StatefulWidget {
  final double itemsTotal; // raw cart total (no tax/delivery)
  final String? deliveryAddress;
  final Map<String, dynamic>? appliedCoupon;
  final double couponDiscount;

  const PaymentPage({
    super.key,
    required this.itemsTotal,
    this.deliveryAddress,
    this.appliedCoupon,
    this.couponDiscount = 0,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

// ─── Payment Method Enum ──────────────────────────────────────────────────────

enum _PaymentMethod { online, cod }

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  _PaymentMethod _selectedMethod = _PaymentMethod.online;

  // ── Calculated values ──────────────────────────────────────────────────────

  bool get _isFreeDelivery =>
      widget.appliedCoupon != null &&
      (widget.appliedCoupon!['couponType'] == 'freeDelivery' ||
          widget.appliedCoupon!['couponType'] == 'free_delivery');

  double get _deliveryCharge => _isFreeDelivery ? 0.0 : 30.0;
  double get _taxAmount => (widget.itemsTotal + _deliveryCharge) * 0.05;
  double get _grandTotal =>
      widget.itemsTotal + _deliveryCharge + _taxAmount - widget.couponDiscount;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay ───────────────────────────────────────────────────────────────

  void _openRazorpay() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final options = {
      'key': 'rzp_live_SIEw0ZGDGbPgTd',
      'amount': (_grandTotal * 100).toInt(),
      'name': 'Bandiwala',
      'description': 'Street food delivery',
      'prefill': {
        'contact':
            FirebaseAuth.instance.currentUser?.phoneNumber ?? '9999999999',
        'email': 'customer@bandiwala.in',
      },
      'external': {
        'wallets': ['paytm'],
      },
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

  // ── COD Order ─────────────────────────────────────────────────────────────

  Future<void> _placeCodOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final orderId = await _createOrderInFirestore(
        paymentId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'cod',
        status: 'confirmed',
      );
      _clearCartSafely();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                paymentId: orderId,
                amount: _grandTotal,
                orderId: orderId,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('COD Order Error: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Firestore order creation ───────────────────────────────────────────────

  Future<String> _createOrderInFirestore({
    required String paymentId,
    required String paymentMethod,
    required String status,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final customerPhone =
        user?.phoneNumber ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> itemsByVendor = {};
    for (final entry in cartStore.cartByVendor.entries) {
      final vendorId = entry.key;
      double vendorSubtotal = 0;
      final itemsCopy = entry.value.items.map((item) {
        vendorSubtotal += item.price * item.quantity;
        return {
          'itemId': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'lineTotal': item.price * item.quantity,
        };
      }).toList();

      itemsByVendor[vendorId] = {
        'vendorName': entry.value.vendorName,
        'items': itemsCopy,
        'vendorSubtotal': vendorSubtotal,
        'status': 'pending',
        'orderReceivedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      };
    }

    final orderData = {
      'orderId': orderId,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod, // 'cod' or 'online'
      'customerPhone': customerPhone,
      'deliveryAddress': widget.deliveryAddress ?? 'Not provided',
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),

      // ── Pricing breakdown ──────────────────────────────────────────────────
      'itemsTotal': widget.itemsTotal,
      'deliveryCharge': _deliveryCharge,
      'taxAmount': _taxAmount,
      'couponDiscount': widget.couponDiscount,
      'grandTotal': _grandTotal,

      // ── Coupon info ────────────────────────────────────────────────────────
      'couponApplied': widget.appliedCoupon != null,
      'couponCode': widget.appliedCoupon?['couponCode'] ?? '',
      'couponType': widget.appliedCoupon?['couponType'] ?? '',
      'freeDelivery': _isFreeDelivery,

      // ── Items ──────────────────────────────────────────────────────────────
      'itemsByVendor': itemsByVendor,
    };

    await FirebaseFirestore.instance.collection('orders').add(orderData);
    debugPrint('✅ Order created: $orderId | Method: $paymentMethod');
    return orderId;
  }

  void _clearCartSafely() {
    final vendorIds = List<String>.from(cartStore.cartByVendor.keys);
    for (final vendorId in vendorIds) {
      final vendorCart = cartStore.cartByVendor[vendorId];
      if (vendorCart != null) {
        final itemIds = List<String>.from(
          vendorCart.items.map((item) => item.id),
        );
        for (final itemId in itemIds) {
          cartStore.updateQuantity(
            vendorId: vendorId,
            itemId: itemId,
            delta: -999,
          );
        }
      }
    }
  }

  // ── Razorpay callbacks ─────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    if (paymentId.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }
    try {
      final orderId = await _createOrderInFirestore(
        paymentId: paymentId,
        paymentMethod: 'online',
        status: 'confirmed',
      );
      _clearCartSafely();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                paymentId: paymentId,
                amount: _grandTotal,
                orderId: orderId,
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Failed: ${response.message ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Wallet: ${response.walletName}');
  }

  // ── Handle primary button tap ──────────────────────────────────────────────

  void _handlePrimaryAction() {
    if (_selectedMethod == _PaymentMethod.cod) {
      _placeCodOrder();
    } else {
      _openRazorpay();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorderGrey),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                // ── Order Summary ──────────────────────────────────────────
                _sectionLabel('Order Summary'),
                const SizedBox(height: 8),
                _orderSummaryCard(),

                const SizedBox(height: 16),

                // ── Delivery Address ───────────────────────────────────────
                if (widget.deliveryAddress != null &&
                    widget.deliveryAddress!.isNotEmpty) ...[
                  _sectionLabel('Delivery To'),
                  const SizedBox(height: 8),
                  _addressCard(),
                  const SizedBox(height: 16),
                ],

                // ── Price Details ──────────────────────────────────────────
                _sectionLabel('Bill Details'),
                const SizedBox(height: 8),
                _billDetailsCard(),

                const SizedBox(height: 16),

                // ── Payment Method ─────────────────────────────────────────
                _sectionLabel('Payment Method'),
                const SizedBox(height: 8),
                _paymentMethodCard(),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Sticky bottom bar ──────────────────────────────────────────
          _bottomBar(),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: kTextGrey,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Order Summary Card ───────────────────────────────────────────────────

  Widget _orderSummaryCard() {
    final vendors = cartStore.cartByVendor.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...vendors.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final isLast = idx == vendors.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kBandiwalaYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          size: 15,
                          color: kBandiwalaYellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.vendorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Items
                ...e.value.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.name}  ×${item.quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vendor subtotal
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Subtotal: ₹${cartStore.vendorTotal(e.key).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Address Card ─────────────────────────────────────────────────────────

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.green.shade600,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivering to',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.deliveryAddress!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bill Details Card ────────────────────────────────────────────────────

  Widget _billDetailsCard() {
    final hasCouponDiscount =
        widget.couponDiscount > 0 &&
        widget.appliedCoupon != null &&
        widget.appliedCoupon!['couponType'] != 'freeDelivery' &&
        widget.appliedCoupon!['couponType'] != 'free_delivery';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _billRow('Items Total', '₹${widget.itemsTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),

          // Delivery row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Delivery Charge',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  if (_isFreeDelivery) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FREE via ${widget.appliedCoupon?['couponCode'] ?? 'coupon'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              _isFreeDelivery
                  ? Row(
                      children: [
                        Text(
                          '₹30',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '₹30',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 10),
          _billRow('Taxes & Charges (5%)', '₹${_taxAmount.toStringAsFixed(0)}'),

          if (hasCouponDiscount) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 13,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.appliedCoupon!['couponCode'] ?? 'Coupon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-₹${widget.couponDiscount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To Pay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kBandiwalaYellow,
                ),
              ),
            ],
          ),

          if (widget.couponDiscount > 0 || _isFreeDelivery) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isFreeDelivery && widget.couponDiscount == 0
                        ? 'You\'re saving ₹30 on delivery!'
                        : 'Total savings: ₹${(widget.couponDiscount + (_isFreeDelivery ? 30 : 0)).toStringAsFixed(0)} on this order',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Payment Method Card ──────────────────────────────────────────────────

  Widget _paymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Online Payment option
          _methodTile(
            method: _PaymentMethod.online,
            icon: Icons.payment_rounded,
            iconBg: Colors.blue.shade50,
            iconColor: Colors.blue.shade600,
            title: 'Pay Online',
            subtitle: 'UPI, Cards, Net Banking, Wallets',
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // COD option
          _methodTile(
            method: _PaymentMethod.cod,
            icon: Icons.money_rounded,
            iconBg: Colors.green.shade50,
            iconColor: Colors.green.shade600,
            title: 'Cash on Delivery',
            subtitle: 'Pay in cash when your order arrives',
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required _PaymentMethod method,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kBandiwalaYellow.withOpacity(0.06) : kWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? kBandiwalaYellow.withOpacity(0.2) : iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? kBandiwalaYellow : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.black87 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: kTextGrey),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kBandiwalaYellow : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? kBandiwalaYellow : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _bottomBar() {
    final isCod = _selectedMethod == _PaymentMethod.cod;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: kBorderGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount row
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCod ? 'Amount to Pay' : 'Total Payable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (!isCod)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kBandiwalaYellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kBandiwalaYellow.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: 12,
                            color: kBandiwalaYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Secured by Razorpay',
                            style: TextStyle(
                              fontSize: 10,
                              color: kBandiwalaYellow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isCod)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pay on Delivery',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Primary button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handlePrimaryAction,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black87,
                        ),
                      )
                    : Icon(
                        isCod ? Icons.shopping_bag_rounded : Icons.payment,
                        size: 20,
                        color: Colors.black87,
                      ),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : isCod
                      ? 'Place Order (COD)  ₹${_grandTotal.toStringAsFixed(0)}'
                      : 'Pay Online  ₹${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBandiwalaYellow,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  disabledBackgroundColor: kBandiwalaYellow.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── Helper row ───────────────────────────────────────────────────────────

  Widget _billRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
