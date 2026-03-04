// cart_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'cart_store.dart';
import 'location_picker_page.dart';
import 'payment_page.dart';
import 'coupons_page.dart';
import 'login_page.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

// ─── Service Zone Model ───────────────────────────────────────────────────────

class _ServiceZone {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  const _ServiceZone({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });
}

const List<_ServiceZone> _kServiceZones = [
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.476388,
    lng: 78.390350,
    radiusMeters: 805.83,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.485210,
    lng: 78.376959,
    radiusMeters: 941.10,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.490998,
    lng: 78.393568,
    radiusMeters: 1020.00,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.493208,
    lng: 78.383281,
    radiusMeters: 750.00,
  ),
  _ServiceZone(
    name: 'Madhapur',
    lat: 17.446960,
    lng: 78.391101,
    radiusMeters: 1225.23,
  ),
  _ServiceZone(
    name: 'Nizampet',
    lat: 17.509248,
    lng: 78.373744,
    radiusMeters: 1471.04,
  ),
  _ServiceZone(
    name: 'Pragathi Nagar',
    lat: 17.522838,
    lng: 78.396081,
    radiusMeters: 1380.00,
  ),
  _ServiceZone(
    name: 'Addagutta',
    lat: 17.503804,
    lng: 78.396080,
    radiusMeters: 1029.53,
  ),
  _ServiceZone(
    name: 'Gajularamaram',
    lat: 17.536753,
    lng: 78.396639,
    radiusMeters: 491.73,
  ),
];

String? _getMatchedZone(double lat, double lng) {
  for (final zone in _kServiceZones) {
    final dist = _haversine(lat, lng, zone.lat, zone.lng);
    if (dist <= zone.radiusMeters) return zone.name;
  }
  return null;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

bool _vendorServesZone(Map<String, dynamic> data, String zone) {
  final zoneLower = zone.toLowerCase().trim();

  final addressField = data['address'];
  if (addressField is String && addressField.isNotEmpty) {
    final parts = addressField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p))) {
      return true;
    }
  }

  final locationsField = data['locations'];
  if (locationsField is List) {
    final locs = locationsField.map((e) => e.toString().trim().toLowerCase());
    if (locs.any((l) => l.contains(zoneLower) || zoneLower.contains(l))) {
      return true;
    }
  } else if (locationsField is String && locationsField.isNotEmpty) {
    final parts = locationsField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p))) {
      return true;
    }
  }

  return false;
}

// ─── CartScreen ───────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String? phoneNumber;
  final SavedLocation? deliveryAddress;

  const CartScreen({
    super.key,
    this.onBackToHome,
    this.phoneNumber,
    this.deliveryAddress,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addressKey = GlobalKey();

  Map<String, dynamic>? _appliedCoupon;
  double _couponDiscount = 0;

  SavedLocation? _selectedAddress;

  Map<String, bool> _vendorDeliverable = {};
  bool _checkingDelivery = false;

  @override
  void initState() {
    super.initState();
    cartStore.addListener(_onCartChanged);
    _selectedAddress = widget.deliveryAddress;
    if (_selectedAddress != null) {
      _checkDeliveryForAllVendors(_selectedAddress!);
    }
  }

  @override
  void didUpdateWidget(CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryAddress != widget.deliveryAddress &&
        widget.deliveryAddress != null) {
      setState(() => _selectedAddress = widget.deliveryAddress);
      _checkDeliveryForAllVendors(widget.deliveryAddress!);
    }
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    if (_appliedCoupon != null) _validateAppliedCoupon();
    if (_selectedAddress != null) {
      _checkDeliveryForAllVendors(_selectedAddress!);
    }
    setState(() {});
  }

  Future<void> _checkDeliveryForAllVendors(SavedLocation address) async {
    if (!mounted) return;
    setState(() => _checkingDelivery = true);

    final addressZone = _getMatchedZone(address.latitude, address.longitude);
    final Map<String, bool> result = {};

    for (final vendorId in cartStore.cartByVendor.keys) {
      try {
        final docSnap = await FirebaseFirestore.instance
            .collection('items')
            .doc(vendorId)
            .get();

        if (!docSnap.exists) {
          result[vendorId] = true;
          continue;
        }

        final data = docSnap.data()!;
        if (addressZone == null) {
          result[vendorId] = false;
        } else {
          result[vendorId] = _vendorServesZone(data, addressZone);
        }
      } catch (e) {
        debugPrint('Zone check error for $vendorId: $e');
        result[vendorId] = true;
      }
    }

    if (mounted) {
      setState(() {
        _vendorDeliverable = result;
        _checkingDelivery = false;
      });
    }
  }

  bool get _hasUndeliverableVendors => _vendorDeliverable.values.any((v) => !v);

  bool _isGuestUser() {
    final phone =
        widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
    return phone == 'GUEST' || phone == null || phone.isEmpty;
  }

  void _showGuestLoginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.login, color: kBandiwalaYellow, size: 28),
            SizedBox(width: 12),
            Text(
              'Login Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Please login to place your order and track your delivery.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Login Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getDocIdFromPhone(String phoneOrDocId) async {
    try {
      if (phoneOrDocId.length > 15) return phoneOrDocId;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('phone', isEqualTo: phoneOrDocId.trim())
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return phoneOrDocId;
    } catch (e) {
      return phoneOrDocId;
    }
  }

  // ─── Coupon ────────────────────────────────────────────────────────────────

  void _validateAppliedCoupon() {
    if (_appliedCoupon == null) return;

    final minAmount = (_appliedCoupon!['minAmount'] ?? 0).toDouble();
    final isWholeApp = _appliedCoupon!['isWholeApp'] ?? true;
    bool isStillValid = true;
    String removalReason = '';

    if (isWholeApp) {
      if (cartStore.grandTotal < minAmount) {
        isStillValid = false;
        removalReason = 'Cart total fell below ₹${minAmount.toInt()}';
      }
    } else {
      final couponVendorIds = List<String>.from(
        _appliedCoupon!['vendorIds'] ?? [],
      );
      final cartVendorIds = cartStore.cartByVendor.keys.toList();
      final matchingVendors = cartVendorIds
          .where((id) => couponVendorIds.contains(id))
          .toList();

      if (matchingVendors.isEmpty) {
        isStillValid = false;
        removalReason = 'No items from required vendors in cart';
      } else {
        double vendorTotal = 0;
        for (var vendorId in matchingVendors) {
          vendorTotal += cartStore.vendorTotal(vendorId);
        }
        if (vendorTotal < minAmount) {
          isStillValid = false;
          removalReason =
              'Total from required vendors fell below ₹${minAmount.toInt()}';
        }
      }
    }

    if (!isStillValid) {
      _removeCoupon();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon removed - $removalReason'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _calculateCouponDiscount() {
    if (_appliedCoupon == null) return 0;
    final couponType = _appliedCoupon!['couponType'] ?? 'discount';
    if (couponType == 'discount') {
      return (_appliedCoupon!['discountAmount'] ?? 0).toDouble();
    } else if (couponType == 'freeDelivery' || couponType == 'free_delivery') {
      return 30.0;
    }
    return 0;
  }

  // ─── Address picker ────────────────────────────────────────────────────────

  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (!mounted) return;
    if (result is SavedLocation) {
      setState(() => _selectedAddress = result);
      await _checkDeliveryForAllVendors(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Delivery address updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToAddress() {
    final ctx = _addressKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Please add delivery address to continue')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  // ─── UPDATED: Place order — passes full data to new PaymentPage ────────────

  void _handlePlaceOrder() {
    if (_isGuestUser()) {
      _showGuestLoginPrompt();
      return;
    }

    if (_selectedAddress == null) {
      _scrollToAddress();
      return;
    }

    if (_hasUndeliverableVendors) {
      _showUndeliverableDialog();
      return;
    }

    // AFTER:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          itemsTotal: cartStore.grandTotal,
          deliveryLocation: _selectedAddress, // ✅ pass full SavedLocation
          appliedCoupon: _appliedCoupon,
          couponDiscount: _couponDiscount,
        ),
      ),
    );
  }

  void _showUndeliverableDialog() {
    final undeliverable = _vendorDeliverable.entries
        .where((e) => !e.value)
        .map((e) => cartStore.cartByVendor[e.key]?.vendorName ?? e.key)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Text(
              'Delivery Unavailable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sorry, we can\'t deliver from the following vendors to your selected address:',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 10),
            ...undeliverable.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Try changing your delivery address to one within our service zones.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickDeliveryLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Change Address'),
          ),
        ],
      ),
    );
  }

  // ─── Coupons ───────────────────────────────────────────────────────────────

  void _showAllCoupons() async {
    final cartVendorPhones = cartStore.cartByVendor.keys.toList();
    final Map<String, double> vendorAmounts = {};
    final Map<String, String> vendorNames = {};
    final List<String> cartVendorDocIds = [];

    for (var phoneOrId in cartVendorPhones) {
      final docId = await _getDocIdFromPhone(phoneOrId);
      cartVendorDocIds.add(docId);
      vendorAmounts[docId] = cartStore.vendorTotal(phoneOrId);
      vendorNames[docId] = cartStore.cartByVendor[phoneOrId]!.vendorName;
    }

    if (!mounted) return;

    final selectedCoupon = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CouponsPage(
          cartAmount: cartStore.grandTotal,
          cartVendorIds: cartVendorDocIds,
          vendorAmounts: vendorAmounts,
          vendorNames: vendorNames,
        ),
      ),
    );

    if (selectedCoupon != null && mounted) {
      _applyCoupon(selectedCoupon);
    }
  }

  void _showCouponSuccessDialog(Map<String, dynamic> coupon) {
    final couponCode = coupon['couponCode'] ?? '';
    final couponType = coupon['couponType'] ?? 'discount';

    String savingsText = '';
    if (couponType == 'discount') {
      savingsText = 'You saved ₹${_couponDiscount.toInt()} with this coupon';
    } else if (couponType == 'freeDelivery' || couponType == 'free_delivery') {
      savingsText = 'You saved ₹30 on delivery!';
    } else if (couponType == 'freebie') {
      savingsText =
          'You got ${coupon['freebieName'] ?? 'free item'} free with this coupon';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 16),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 50,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Text(
                      couponType == 'discount'
                          ? '₹${_couponDiscount.toInt()}'
                          : '✓',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '$couponCode applied!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                savingsText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'That feels amazing, right?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: kBandiwalaYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyCoupon(Map<String, dynamic> coupon) {
    setState(() {
      _appliedCoupon = coupon;
      _couponDiscount = _calculateCouponDiscount();
    });
    if (coupon['id'] != null) {
      FirebaseFirestore.instance.collection('coupons').doc(coupon['id']).update(
        {'currentUsage': FieldValue.increment(1)},
      );
    }
    _showCouponSuccessDialog(coupon);
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
    });
  }

  void _handleBack() => widget.onBackToHome?.call();

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasItems = cartStore.hasItems;
    final vendorIds = cartStore.cartByVendor.keys.toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Home',
                    ),
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (hasItems)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kBandiwalaYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cartStore.totalItemCount} items',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: !hasItems
                    ? _buildEmptyState()
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // ── Vendor sections ────────────────────────────
                          ...cartStore.cartByVendor.entries.map((entry) {
                            final canDeliver =
                                _vendorDeliverable[entry.key] ?? true;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VendorCartSection(
                                  vendorId: entry.key,
                                  vendorCart: entry.value,
                                  onQuantityChanged: (itemId, delta) {
                                    cartStore.updateQuantity(
                                      vendorId: entry.key,
                                      itemId: itemId,
                                      delta: delta,
                                    );
                                  },
                                  vendorTotal: cartStore.vendorTotal(entry.key),
                                ),
                                if (!canDeliver && _selectedAddress != null)
                                  _DeliveryUnavailableBanner(
                                    vendorName: entry.value.vendorName,
                                    onChangeAddress: _pickDeliveryLocation,
                                  ),
                              ],
                            );
                          }),

                          if (vendorIds.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            YouMayLikeSection(vendorIds: vendorIds),
                          ],

                          const SizedBox(height: 20),

                          // ── Address ────────────────────────────────────
                          AddressSection(
                            key: _addressKey,
                            selectedAddress: _selectedAddress,
                            onTapLocation: _pickDeliveryLocation,
                            isChecking: _checkingDelivery,
                          ),

                          const SizedBox(height: 16),

                          // ── Enhanced Coupon Section ────────────────────
                          CouponSectionWidget(
                            appliedCoupon: _appliedCoupon,
                            couponDiscount: _couponDiscount,
                            onViewAllCoupons: _showAllCoupons,
                            onRemoveCoupon: _removeCoupon,
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
              ),

              // ── UPDATED Bottom Bar — only items total, no price breakdown ──
              if (hasItems) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UPDATED Bottom Bar ───────────────────────────────────────────────────
  // Shows only: items total (raw product value)
  // No PriceBreakdownWidget, no tax/delivery confusion

  Widget _buildBottomBar() {
    final isFreeDelivery =
        _appliedCoupon != null &&
        (_appliedCoupon!['couponType'] == 'freeDelivery' ||
            _appliedCoupon!['couponType'] == 'free_delivery');
    final hasCouponSavings = _couponDiscount > 0 || isFreeDelivery;
    final savingsAmount = _couponDiscount + (isFreeDelivery ? 30.0 : 0.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Savings strip — shown only when coupon applied
          if (hasCouponSavings) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    isFreeDelivery && _couponDiscount == 0
                        ? 'Free delivery applied!'
                        : 'Total savings: ₹${savingsAmount.toStringAsFixed(0)} applied',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Items total row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${cartStore.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                '+ taxes & delivery',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const Spacer(),
            ],
          ),

          // Delivery warning strip
          if (_hasUndeliverableVendors && _selectedAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Some vendors can\'t deliver to your address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickDeliveryLocation,
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _checkingDelivery ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hasUndeliverableVendors && _selectedAddress != null
                    ? Colors.grey.shade300
                    : kBandiwalaYellow,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _checkingDelivery
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black54,
                      ),
                    )
                  : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from nearby vendors',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery Unavailable Banner ──────────────────────────────────────────────

class _DeliveryUnavailableBanner extends StatelessWidget {
  final String vendorName;
  final VoidCallback onChangeAddress;

  const _DeliveryUnavailableBanner({
    required this.vendorName,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.delivery_dining, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sorry, we can\'t deliver from $vendorName to your address right now.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onChangeAddress,
                  child: Text(
                    'Change delivery address →',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      decoration: TextDecoration.underline,
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
}

// ─── AddressSection ───────────────────────────────────────────────────────────

class AddressSection extends StatelessWidget {
  final SavedLocation? selectedAddress;
  final VoidCallback onTapLocation;
  final bool isChecking;

  const AddressSection({
    super.key,
    required this.selectedAddress,
    required this.onTapLocation,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = selectedAddress != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAddress ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapLocation,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasAddress
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kBandiwalaYellow,
                          ),
                        )
                      : Icon(
                          hasAddress
                              ? Icons.location_on
                              : Icons.add_location_alt,
                          color: hasAddress
                              ? Colors.green
                              : Colors.grey.shade700,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hasAddress ? 'Delivery Address' : 'Add Address',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!hasAddress) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                          if (hasAddress && selectedAddress!.label != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kBandiwalaYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedAddress!.label!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAddress
                            ? selectedAddress!.address
                            : 'Tap to select location',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasAddress
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasAddress &&
                          selectedAddress!.houseNo != null &&
                          selectedAddress!.houseNo!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            selectedAddress!.houseNo!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── YouMayLikeSection ────────────────────────────────────────────────────────

class YouMayLikeSection extends StatelessWidget {
  final List<String> vendorIds;
  const YouMayLikeSection({super.key, required this.vendorIds});

  @override
  Widget build(BuildContext context) {
    final cartItemIds = <String>{};
    for (var vendorCart in cartStore.cartByVendor.values) {
      for (var item in vendorCart.items) {
        cartItemIds.add(item.id);
      }
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchVendorItemsWithDocIds(vendorIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 175,
            child: Center(
              child: CircularProgressIndicator(
                color: kBandiwalaYellow,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final allItems = snapshot.data!
            .where((item) => !cartItemIds.contains(item['id']))
            .toList();
        if (allItems.isEmpty) return const SizedBox.shrink();
        allItems.shuffle();
        final displayItems = allItems.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Complete your meal with',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 175,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == displayItems.length - 1 ? 0 : 10,
                    ),
                    child: SuggestionCard(item: displayItems[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchVendorItemsWithDocIds(
    List<String> vendorPhones,
  ) async {
    final allItems = <Map<String, dynamic>>[];
    try {
      for (var phoneOrId in vendorPhones) {
        QuerySnapshot vendorQuery;
        String vendorDocId = phoneOrId;
        String phoneNumber = phoneOrId;
        String vendorName = 'Restaurant';

        if (phoneOrId.length <= 15) {
          vendorQuery = await FirebaseFirestore.instance
              .collection('vendors')
              .where('phone', isEqualTo: phoneOrId.trim())
              .limit(1)
              .get();
          if (vendorQuery.docs.isNotEmpty) {
            vendorDocId = vendorQuery.docs.first.id;
            final d = vendorQuery.docs.first.data() as Map<String, dynamic>;
            vendorName = d['name'] ?? 'Restaurant';
            phoneNumber = phoneOrId;
          }
        } else {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(phoneOrId)
              .get();
          if (vendorDoc.exists) {
            final d = vendorDoc.data();
            phoneNumber = d?['phone'] ?? phoneOrId;
            vendorName = d?['name'] ?? 'Restaurant';
          }
        }

        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('items')
            .doc(phoneNumber)
            .collection('items')
            .where('isAvailable', isEqualTo: true)
            .limit(20)
            .get();

        for (var doc in itemsSnapshot.docs) {
          allItems.add({
            'id': doc.id,
            'vendorId': vendorDocId,
            'vendorName': vendorName,
            ...doc.data(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching vendor items: $e');
    }
    return allItems;
  }
}

// ─── SuggestionCard ───────────────────────────────────────────────────────────

class SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const SuggestionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? 'Item';
    final price = (item['price'] ?? 0).toDouble();
    final imageUrl = item['imageUrl'] ?? '';
    final isVeg = item['isVeg'] ?? true;
    final itemId = item['id'] ?? '';
    final vendorId = item['vendorId'] ?? '';
    final vendorName = item['vendorName'] ?? 'Restaurant';

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 140,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 95,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, size: 28),
                        ),
                      )
                    : Container(
                        width: 140,
                        height: 95,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant, size: 28),
                      ),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isVeg ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isVeg ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        cartStore.addItem(
                          vendorId: vendorId,
                          vendorName: vendorName,
                          itemId: itemId,
                          itemName: name,
                          price: price,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Icon(
                        Icons.add,
                        color: Colors.pink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ENHANCED CouponSectionWidget ─────────────────────────────────────────────

class CouponSectionWidget extends StatelessWidget {
  final Map<String, dynamic>? appliedCoupon;
  final double couponDiscount;
  final VoidCallback onViewAllCoupons;
  final VoidCallback onRemoveCoupon;

  const CouponSectionWidget({
    super.key,
    required this.appliedCoupon,
    required this.couponDiscount,
    required this.onViewAllCoupons,
    required this.onRemoveCoupon,
  });

  bool get _isFreeDelivery =>
      appliedCoupon != null &&
      (appliedCoupon!['couponType'] == 'freeDelivery' ||
          appliedCoupon!['couponType'] == 'free_delivery');

  bool get _isFreebie =>
      appliedCoupon != null && appliedCoupon!['couponType'] == 'freebie';

  @override
  Widget build(BuildContext context) {
    final hasApplied = appliedCoupon != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasApplied ? Colors.green.shade300 : Colors.grey.shade300,
          width: hasApplied ? 1.5 : 1,
        ),
        boxShadow: hasApplied
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // ── Tap row ───────────────────────────────────────────────────
          InkWell(
            onTap: onViewAllCoupons,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasApplied
                              ? 'Offer Applied!'
                              : 'Apply Offer / Coupon',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: hasApplied
                                ? Colors.green.shade700
                                : Colors.black87,
                          ),
                        ),
                        if (!hasApplied) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Save more with exclusive offers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!hasApplied) ...[
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
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: onRemoveCoupon,
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
                ],
              ),
            ),
          ),

          // ── Applied coupon banner ─────────────────────────────────────
          if (hasApplied) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100.withOpacity(0.5),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  // Dashed divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: List.generate(
                        30,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color: i.isEven
                                ? Colors.green.shade300
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Row(
                      children: [
                        // Coupon type icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              _isFreebie &&
                                  appliedCoupon!['freebieImageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    appliedCoupon!['freebieImageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.redeem,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isFreeDelivery
                                      ? Icons.delivery_dining_rounded
                                      : _isFreebie
                                      ? Icons.redeem_rounded
                                      : Icons.currency_rupee_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Code pill
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
                                  appliedCoupon!['couponCode'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _getSavingsText(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Applied successfully 🎉',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Savings badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isFreeDelivery && couponDiscount == 0
                                    ? 'FREE'
                                    : '-₹${couponDiscount.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              if (_isFreeDelivery)
                                const Text(
                                  'delivery',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  String _getSavingsText() {
    if (_isFreeDelivery) return 'Free delivery on this order';
    if (_isFreebie) {
      return 'Free: ${appliedCoupon!['freebieName'] ?? 'item'} added';
    }
    return 'You save ₹${couponDiscount.toInt()} on this order';
  }
}

// ─── VendorCartSection ────────────────────────────────────────────────────────

class VendorCartSection extends StatelessWidget {
  final String vendorId;
  final VendorCart vendorCart;
  final void Function(String itemId, int delta) onQuantityChanged;
  final double vendorTotal;

  const VendorCartSection({
    super.key,
    required this.vendorId,
    required this.vendorCart,
    required this.onQuantityChanged,
    required this.vendorTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vendorCart.vendorName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...vendorCart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartLineItem(
                item: item,
                onQuantityChanged: (delta) => onQuantityChanged(item.id, delta),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ₹${vendorTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CartLineItem ─────────────────────────────────────────────────────────────

class CartLineItem extends StatelessWidget {
  final CartItem item;
  final void Function(int delta) onQuantityChanged;

  const CartLineItem({
    super.key,
    required this.item,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: const Icon(Icons.circle, size: 10, color: Colors.grey),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBandiwalaYellow, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _btn(
                    item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                    () => onQuantityChanged(-1),
                    isRemove: item.quantity == 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _btn(Icons.add, () => onQuantityChanged(1)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {bool isRemove = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 22,
          color: isRemove ? Colors.red.shade400 : kBandiwalaYellow,
        ),
      ),
    );
  }
}
