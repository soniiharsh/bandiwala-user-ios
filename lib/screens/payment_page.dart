import 'package:BandiWala/providers/pricing_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../providers/coupons_provider.dart';
import '../models/order.dart';
import '../models/app_user.dart';
import '../services/payment_service.dart';
import 'payment_success_page.dart';
import 'coupons_page.dart';
import '../core/theme/theme.dart';
import '../core/navigation/app_page_route.dart';

const kBandiwalaYellow = AppColors.primary;
const kWhite = Colors.white;
const kBorderGrey = Color(0xFFE5E7EB);
const kTextGrey = Color(0xFF6B7280);
const kBgGrey = Color(0xFFF9FAFB);

// ─── Pricing Config Model ─────────────────────────────────────────────────────

const double kFoodTaxPercent = 5.0;
const double kDeliveryTaxPercent = 18.0;
const double kPlatformFeeTaxPercent = 18.0;

class PricingConfig {
  final double deliveryCharge;
  final double platformFee;
  final double foodTaxPercent;
  final double deliveryTaxPercent;
  final double platformFeeTaxPercent;

  const PricingConfig({
    required this.deliveryCharge,
    required this.platformFee,
    this.foodTaxPercent = kFoodTaxPercent,
    this.deliveryTaxPercent = kDeliveryTaxPercent,
    this.platformFeeTaxPercent = kPlatformFeeTaxPercent,
  });

  factory PricingConfig.defaults() =>
      const PricingConfig(deliveryCharge: 29, platformFee: 10);

  factory PricingConfig.fromMap(Map<String, dynamic> map) => PricingConfig(
    deliveryCharge: (map['deliveryCharge'] ?? 29).toDouble(),
    platformFee: (map['platformFee'] ?? 10).toDouble(),
    foodTaxPercent: (map['foodTaxPercent'] ?? kFoodTaxPercent).toDouble(),
    deliveryTaxPercent: (map['deliveryTaxPercent'] ?? kDeliveryTaxPercent)
        .toDouble(),
    platformFeeTaxPercent:
        (map['platformFeeTaxPercent'] ?? kPlatformFeeTaxPercent).toDouble(),
  );
}

// ─── PaymentPage ──────────────────────────────────────────────────────────────

class PaymentPage extends ConsumerStatefulWidget {
  final double itemsTotal;
  final SavedAddress? deliveryLocation;

  const PaymentPage({
    super.key,
    required this.itemsTotal,
    this.deliveryLocation,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

enum _PaymentMethod { online, cod }

class _PaymentPageState extends ConsumerState<PaymentPage> {
  late PaymentService _paymentService;
  bool _isProcessing = false;
  bool _taxBreakdownExpanded = false;
  _PaymentMethod _selectedMethod = _PaymentMethod.online;

  Map<String, dynamic>? _appliedCoupon;
  double _couponDiscount = 0;

  // ── Pricing ───────────────────────────────────────────────────────────────

  PricingConfig get _pricing {
    final data = ref.watch(pricingConfigProvider).valueOrNull ?? {};
    return data.isEmpty
        ? PricingConfig.defaults()
        : PricingConfig.fromMap(data);
  }

  // ── Computed values ───────────────────────────────────────────────────────

  bool get _isFreeDelivery => _appliedCoupon?['couponType'] == 'free_delivery';

  double get _deliveryCharge => _isFreeDelivery ? 0.0 : _pricing.deliveryCharge;

  double get _platformFee => _pricing.platformFee;

  double get _foodTax => widget.itemsTotal * (_pricing.foodTaxPercent / 100);

  double get _deliveryTax =>
      _deliveryCharge * (_pricing.deliveryTaxPercent / 100);

  double get _platformFeeTax =>
      _platformFee * (_pricing.platformFeeTaxPercent / 100);

  double get _totalTaxAmount => _foodTax + _deliveryTax + _platformFeeTax;

  double get _grandTotal {
    final discount = _isFreeDelivery ? 0.0 : _couponDiscount;
    return widget.itemsTotal +
        _deliveryCharge +
        _platformFee +
        _totalTaxAmount -
        discount;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(
      buildOrder: _buildOrder,
      onSuccess: _onOrderSuccess,
      onError: _onOrderError,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  // ── Order builder (snapshot of current state) ─────────────────────────────

  AppOrder _buildOrder() {
    final user = FirebaseAuth.instance.currentUser;
    final cart = ref.read(cartProvider);
    final loc = widget.deliveryLocation!;

    final List<String> vendorIds = [];
    final Map<String, VendorOrder> itemsByVendor = {};

    for (final entry in cart.cartByVendor.entries) {
      vendorIds.add(entry.key);
      itemsByVendor[entry.key] = VendorOrder(
        vendorName: entry.value.vendorName,
        items: {
          for (final item in entry.value.items)
            item.id: OrderItem(
              name: item.name,
              price: item.price,
              quantity: item.quantity,
            ),
        },
      );
    }

    return AppOrder(
      id: '',
      userId: user?.uid ?? '',
      customerPhone: loc.phone,
      deliveryAddress: OrderDeliveryAddress.fromSavedAddress(loc),
      itemsByVendor: itemsByVendor,
      vendorIds: vendorIds,
      paymentMethod: '',
      paymentId: '',
      deliveryFee: _deliveryCharge,
      platformFee: _platformFee,
      foodTax: _foodTax,
      deliveryTax: _deliveryTax,
      platformTax: _platformFeeTax > 0,
      couponApplied: _appliedCoupon != null,
      couponCode: _appliedCoupon?['couponCode'] ?? '',
      couponType: _appliedCoupon?['couponType'] ?? '',
      couponDiscount: _isFreeDelivery ? 0.0 : _couponDiscount,
      couponMaxDiscountableAmount:
          (_appliedCoupon?['maxDiscountableAmount'] ?? 0).toDouble(),
      grandTotal: _grandTotal,
      status: 'order_created',
    );
  }

  // ── Payment callbacks ─────────────────────────────────────────────────────

  void _onOrderSuccess(String orderId) {
    ref.read(cartProvider.notifier).clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        AppPageRoute(
          type: PageTransitionType.scale,
          builder: (_) => PaymentSuccessPage(
            paymentId: orderId,
            amount: _grandTotal,
            orderId: orderId,
          ),
        ),
      );
    });
  }

  void _onOrderError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ── Coupon logic ──────────────────────────────────────────────────────────

  double _calculateCouponDiscount() {
    if (_appliedCoupon == null) return 0;
    final type = _appliedCoupon!['couponType'] ?? '';
    if (type == 'free_delivery') return 0.0;

    final total =
        widget.itemsTotal + _deliveryCharge + _platformFee + _totalTaxAmount;
    final discount = (_appliedCoupon!['discount'] ?? 0).toDouble();
    final maxDiscountable = (_appliedCoupon!['maxDiscountableAmount'] ?? 0)
        .toDouble();

    if (type == 'flat_off') return discount;
    if (type == 'discount') {
      final pct = total * (discount / 100);
      return maxDiscountable > 0
          ? pct.clamp(0, maxDiscountable).toDouble()
          : pct;
    }
    return 0;
  }

  Future<void> _showAllCoupons() async {
    final cart = ref.read(cartProvider);
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      AppPageRoute(
        type: PageTransitionType.slideUp,
        builder: (_) => CouponsPage(cartAmount: cart.grandTotal),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _appliedCoupon = selected;
        _couponDiscount = _calculateCouponDiscount();
      });
      if (selected['id'] != null) incrementCouponUsage(selected['id']);
    }
  }

  void _removeCoupon() => setState(() {
    _appliedCoupon = null;
    _couponDiscount = 0;
  });

  // ── Actions ───────────────────────────────────────────────────────────────

  void _handlePrimaryAction() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    if (_selectedMethod == _PaymentMethod.cod) {
      _showCodConfirmationDialog();
    } else {
      _paymentService.openRazorpay(_grandTotal);
    }
  }

  Future<void> _showCodConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CodConfirmDialog(grandTotal: _grandTotal),
    );
    if (confirmed == true) {
      await _paymentService.placeCodOrder();
    } else {
      setState(() => _isProcessing = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
      body: ref.watch(pricingConfigProvider).isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kBandiwalaYellow),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _sectionLabel('Order Summary'),
                      const SizedBox(height: 8),
                      _orderSummaryCard(),
                      const SizedBox(height: 16),
                      if (widget.deliveryLocation != null) ...[
                        _sectionLabel('Delivery To'),
                        const SizedBox(height: 8),
                        _addressCard(),
                        const SizedBox(height: 16),
                      ],
                      _sectionLabel('Bill Details'),
                      const SizedBox(height: 8),
                      _billDetailsCard(),
                      const SizedBox(height: 16),
                      _sectionLabel('Offers & Coupons'),
                      const SizedBox(height: 8),
                      _couponSection(),
                      const SizedBox(height: 16),
                      _sectionLabel('Payment Method'),
                      const SizedBox(height: 8),
                      _paymentMethodCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                _bottomBar(),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: kTextGrey,
      letterSpacing: 0.5,
    ),
  );

  Widget _orderSummaryCard() {
    final cart = ref.watch(cartProvider);
    final vendors = cart.cartByVendor.entries.toList();
    return _card(
      child: Column(
        children: vendors.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final isLast = idx == vendors.length - 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Subtotal: ₹${cart.vendorTotal(e.key).toStringAsFixed(0)}',
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
        }).toList(),
      ),
    );
  }

  Widget _addressCard() {
    final loc = widget.deliveryLocation!;
    return _card(
      padding: const EdgeInsets.all(14),
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
                  loc.fullDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billDetailsCard() {
    final hasCouponDiscount =
        _couponDiscount > 0 &&
        _appliedCoupon != null &&
        _appliedCoupon!['couponType'] != 'free_delivery';
    final totalSavings = _isFreeDelivery
        ? _pricing.deliveryCharge
        : _couponDiscount;

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _billRow('Items Total', '₹${widget.itemsTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
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
                        'FREE via ${_appliedCoupon?['couponCode'] ?? 'coupon'}',
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
                          '₹${_pricing.deliveryCharge.toStringAsFixed(0)}',
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
                      '₹${_pricing.deliveryCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          _billRow(
            'Platform Fee',
            '₹${_platformFee.toStringAsFixed(0)}',
            labelColor: Colors.grey.shade700,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                setState(() => _taxBreakdownExpanded = !_taxBreakdownExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Taxes & Charges',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _taxBreakdownExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                Text(
                  '₹${_totalTaxAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _taxBreakdownExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _taxRow('GST on Food', _pricing.foodTaxPercent, _foodTax),
                  if (!_isFreeDelivery) ...[
                    const SizedBox(height: 6),
                    _taxRow(
                      'GST on Delivery',
                      _pricing.deliveryTaxPercent,
                      _deliveryTax,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _taxRow(
                    'GST on Platform Fee',
                    _pricing.platformFeeTaxPercent,
                    _platformFeeTax,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
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
                      _appliedCoupon!['couponCode'] ?? 'Coupon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-₹${_couponDiscount.toStringAsFixed(0)}',
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
          if (totalSavings > 0) ...[
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
                  Expanded(
                    child: Text(
                      _isFreeDelivery && _couponDiscount == 0
                          ? "You're saving ₹${_pricing.deliveryCharge.toStringAsFixed(0)} on delivery!"
                          : 'Total savings: ₹${totalSavings.toStringAsFixed(0)} on this order',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _couponSection() {
    final hasApplied = _appliedCoupon != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasApplied ? Colors.green.shade300 : kBorderGrey,
          width: hasApplied ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _showAllCoupons,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: hasApplied ? Radius.zero : const Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasApplied
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.orange.shade300, Colors.orange.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasApplied
                          ? Icons.check_circle_outline_rounded
                          : Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasApplied ? 'Offer Applied!' : 'Apply Offer / Coupon',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: hasApplied
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (!hasApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kBandiwalaYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 11,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _removeCoupon,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasApplied)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _appliedCoupon!['couponCode'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isFreeDelivery
                          ? 'Free delivery applied'
                          : 'You save ₹${_couponDiscount.toInt()} on this order',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isFreeDelivery
                          ? 'FREE\ndelivery'
                          : '-₹${_couponDiscount.toInt()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentMethodCard() {
    return _card(
      child: Column(
        children: [
          _methodTile(
            method: _PaymentMethod.online,
            icon: Icons.payment_rounded,
            iconBg: Colors.blue.shade50,
            iconColor: Colors.blue.shade600,
            title: 'Pay Online',
            subtitle: 'UPI, Cards, Net Banking, Wallets',
          ),
          Divider(height: 1, color: Colors.grey.shade100),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: kTextGrey),
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: 12,
                            color: kBandiwalaYellow,
                          ),
                          SizedBox(width: 4),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding,
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
    child: child,
  );

  Widget _billRow(String label, String value, {Color? labelColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: labelColor ?? Colors.grey.shade700,
        ),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _taxRow(String label, double percent, double amount) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          '$label (${percent.toStringAsFixed(0)}%)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ),
      Text(
        '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  );
}

// ─── COD Confirmation Dialog ──────────────────────────────────────────────────

class _CodConfirmDialog extends StatelessWidget {
  final double grandTotal;
  const _CodConfirmDialog({required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.money_rounded,
              color: Colors.green.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Cash on Delivery',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            'You are placing an order with Cash on Delivery.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBandiwalaYellow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount to pay on delivery',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kBandiwalaYellow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Please keep exact change ready. Our delivery partner will collect payment at your doorstep.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBandiwalaYellow,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
