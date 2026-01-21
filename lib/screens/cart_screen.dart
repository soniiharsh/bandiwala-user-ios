import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_store.dart';
import 'location_picker_page.dart';
import 'payment_page.dart';
import 'coupons_page.dart';
import 'login_page.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String? phoneNumber;

  const CartScreen({
    super.key,
    this.onBackToHome,
    this.phoneNumber,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _showPriceBreakdown = false;
  final TextEditingController _addressController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addressKey = GlobalKey();

  Map<String, dynamic>? _appliedCoupon;
  double _couponDiscount = 0;

  @override
  void initState() {
    super.initState();
    cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    if (_appliedCoupon != null) {
      _validateAppliedCoupon();
    }
    setState(() {});
  }

  bool _isGuestUser() {
    final phone = widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
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
      if (phoneOrDocId.length > 15) {
        return phoneOrDocId;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('phone', isEqualTo: phoneOrDocId.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        print('📱 → 🆔 Converted: $phoneOrDocId → $docId');
        return docId;
      }

      print('⚠️ No vendor found for: $phoneOrDocId');
      return phoneOrDocId;
    } catch (e) {
      print('❌ Error converting phone to doc ID: $e');
      return phoneOrDocId;
    }
  }

  void _validateAppliedCoupon() {
    if (_appliedCoupon == null) return;

    print('\n🔍 === VALIDATING APPLIED COUPON ===');
    print('Coupon Code: ${_appliedCoupon!['couponCode']}');

    final minAmount = (_appliedCoupon!['minAmount'] ?? 0).toDouble();
    final isWholeApp = _appliedCoupon!['isWholeApp'] ?? true;
    bool isStillValid = true;
    String removalReason = '';

    if (isWholeApp) {
      print('📱 Whole App Coupon');
      print('   Cart Total: ₹${cartStore.grandTotal}');
      print('   Required Minimum: ₹$minAmount');

      if (cartStore.grandTotal < minAmount) {
        isStillValid = false;
        removalReason = 'Cart total fell below ₹${minAmount.toInt()}';
      }
    } else {
      print('🏪 Vendor-Specific Coupon');

      final couponVendorIds = List<String>.from(_appliedCoupon!['vendorIds'] ?? []);
      print('   Required Vendor IDs: $couponVendorIds');

      final cartVendorIds = cartStore.cartByVendor.keys.toList();
      print('   Current Cart Vendor IDs: $cartVendorIds');

      final matchingVendors = cartVendorIds
          .where((id) => couponVendorIds.contains(id))
          .toList();

      print('   Matching Vendors: $matchingVendors');

      if (matchingVendors.isEmpty) {
        isStillValid = false;
        removalReason = 'No items from required vendors in cart';
        print('   ❌ No matching vendors found');
      } else {
        double vendorTotal = 0;
        for (var vendorId in matchingVendors) {
          final amount = cartStore.vendorTotal(vendorId);
          vendorTotal += amount;
          print('   - $vendorId: ₹$amount');
        }

        print('   Total from matching vendors: ₹$vendorTotal');
        print('   Required Minimum: ₹$minAmount');

        if (vendorTotal < minAmount) {
          isStillValid = false;
          removalReason = 'Total from required vendors fell below ₹${minAmount.toInt()}';
          print('   ❌ Amount too low');
        } else {
          print('   ✅ Still valid');
        }
      }
    }

    if (!isStillValid) {
      print('❌ Removing coupon: $removalReason');
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
    } else {
      print('✅ Coupon still valid');
    }
  }

  double _calculateCouponDiscount() {
    if (_appliedCoupon == null) return 0;

    final couponType = _appliedCoupon!['couponType'] ?? 'discount';
    if (couponType == 'discount') {
      return (_appliedCoupon!['discountAmount'] ?? 0).toDouble();
    } else if (couponType == 'freeDelivery') {
      return 30.0;
    }
    return 0;
  }

  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (!mounted) return;

    if (result is SavedLocation) {
      setState(() {
        _addressController.text = result.address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Delivery address added'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToAddress() {
    final addressContext = _addressKey.currentContext;
    if (addressContext != null) {
      Scrollable.ensureVisible(
        addressContext,
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
              Expanded(
                child: Text('Please add delivery address to continue'),
              ),
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

  void _handlePlaceOrder() {
    if (_isGuestUser()) {
      _showGuestLoginPrompt();
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _scrollToAddress();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          amount: _calculateFinalTotal(),
          deliveryAddress: _addressController.text,
        ),
      ),
    );
  }

  double _calculateFinalTotal() {
    final delivery = _appliedCoupon != null &&
        _appliedCoupon!['couponType'] == 'freeDelivery'
        ? 0.0
        : 30.0;
    final taxes = (cartStore.grandTotal + delivery) * 0.05;
    final discount = _calculateCouponDiscount();
    final total = cartStore.grandTotal + delivery + taxes - discount;
    return total > 0 ? total : 0;
  }

  void _showAllCoupons() async {
    print('\n🔄 === CONVERTING PHONE NUMBERS TO DOCUMENT IDs ===');

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

    print('\n🛒 === CART DATA FOR COUPONS (CONVERTED) ===');
    print('Total Cart Amount: ₹${cartStore.grandTotal}');
    print('Number of Vendors: ${cartVendorDocIds.length}');
    print('\nVendor Breakdown:');
    for (var vendorId in cartVendorDocIds) {
      print('  📦 "${vendorNames[vendorId]}"');
      print('     Document ID: "$vendorId"');
      print('     Amount: ₹${vendorAmounts[vendorId]}');
    }
    print('================================\n');

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

  // ✅ NEW: Show coupon success dialog instead of snackbar
  void _showCouponSuccessDialog(Map<String, dynamic> coupon) {
    final couponCode = coupon['couponCode'] ?? '';
    final couponType = coupon['couponType'] ?? 'discount';

    String savingsText = '';
    if (couponType == 'discount') {
      savingsText = 'You saved ₹${_couponDiscount.toInt()} with this coupon';
    } else if (couponType == 'freeDelivery') {
      savingsText = 'You saved ₹30 with this coupon';
    } else if (couponType == 'freebie') {
      final freebieName = coupon['freebieName'] ?? 'free item';
      savingsText = 'You got $freebieName free with this coupon';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coupon icon with percentage
            Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 16),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade300,
                      Colors.orange.shade500,
                    ],
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
                          ? '${(_couponDiscount).toInt()}%'
                          : '✓',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Coupon code
            Text(
              '$couponCode applied',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            // Savings text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                savingsText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Subtext
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

            // Close button
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kBandiwalaYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
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
      FirebaseFirestore.instance.collection('coupons').doc(coupon['id']).update({
        'currentUsage': FieldValue.increment(1),
      });
    }

    // ✅ Show dialog instead of snackbar
    _showCouponSuccessDialog(coupon);
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
    });
  }

  void _handleBack() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = cartStore.hasItems;
    final vendorIds = cartStore.cartByVendor.keys.toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
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
                    ...cartStore.cartByVendor.entries.map(
                          (entry) => VendorCartSection(
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
                    ),
                    if (vendorIds.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      YouMayLikeSection(vendorIds: vendorIds),
                    ],
                    const SizedBox(height: 20),
                    AddressSection(
                      key: _addressKey,
                      addressController: _addressController,
                      onTapLocation: _pickDeliveryLocation,
                    ),
                    const SizedBox(height: 16),
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
              if (hasItems)
                Container(
                  padding: const EdgeInsets.all(16),
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
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showPriceBreakdown = !_showPriceBreakdown;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Text(
                                'Grand total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _showPriceBreakdown
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              const Spacer(),
                              Text(
                                '₹${_calculateFinalTotal().toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showPriceBreakdown) ...[
                        const SizedBox(height: 8),
                        PriceBreakdownWidget(
                          grandTotal: cartStore.grandTotal,
                          couponDiscount: _couponDiscount,
                          appliedCoupon: _appliedCoupon,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handlePlaceOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBandiwalaYellow,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep all other classes (YouMayLikeSection, SuggestionCard, AddressSection,
// CouponSectionWidget, PriceBreakdownWidget, VendorCartSection, CartLineItem)
// exactly as they are in the original code - no changes needed


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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
                  final item = displayItems[index];
                  return Padding(
                    padding: EdgeInsets.only(
                        right: index == displayItems.length - 1 ? 0 : 10),
                    child: SuggestionCard(item: item),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ FIXED: Convert phone to document ID when fetching items
  Future<List<Map<String, dynamic>>> _fetchVendorItemsWithDocIds(
      List<String> vendorPhones) async {
    final allItems = <Map<String, dynamic>>[];

    try {
      for (var phoneOrId in vendorPhones) {
        // Try to fetch vendor by phone number to get document ID
        QuerySnapshot vendorQuery;
        String vendorDocId = phoneOrId;
        String phoneNumber = phoneOrId;
        String vendorName = 'Restaurant';

        // Check if it's a phone number (10 digits) or document ID
        if (phoneOrId.length <= 15) {
          // It's a phone number, find the document ID
          vendorQuery = await FirebaseFirestore.instance
              .collection('vendors')
              .where('phone', isEqualTo: phoneOrId.trim())
              .limit(1)
              .get();

          if (vendorQuery.docs.isNotEmpty) {
            vendorDocId = vendorQuery.docs.first.id;
            final vendorData = vendorQuery.docs.first.data() as Map<String, dynamic>;
            vendorName = vendorData['name'] ?? 'Restaurant';
            phoneNumber = phoneOrId;
          }
        } else {
          // It's already a document ID
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(phoneOrId)
              .get();

          if (vendorDoc.exists) {
            final vendorData = vendorDoc.data();
            phoneNumber = vendorData?['phone'] ?? phoneOrId;
            vendorName = vendorData?['name'] ?? 'Restaurant';
          }
        }

        // Fetch items using phone number path
        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('items')
            .doc(phoneNumber)
            .collection('items')
            .where('isAvailable', isEqualTo: true)
            .limit(20)
            .get();

        for (var doc in itemsSnapshot.docs) {
          final data = doc.data();
          allItems.add({
            'id': doc.id,
            'vendorId': vendorDocId, // ← Use document ID, not phone!
            'vendorName': vendorName,
            ...data,
          });
        }
      }
    } catch (e) {
      print('Error fetching vendor items: $e');
    }

    return allItems;
  }
}

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
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
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
                    color: Colors.black87,
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

class AddressSection extends StatelessWidget {
  final TextEditingController addressController;
  final VoidCallback onTapLocation;

  const AddressSection({
    super.key,
    required this.addressController,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = addressController.text.trim().isNotEmpty;

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
                  child: Icon(
                    hasAddress ? Icons.location_on : Icons.add_location_alt,
                    color: hasAddress ? Colors.green : Colors.grey.shade700,
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAddress
                            ? addressController.text
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

  @override
  Widget build(BuildContext context) {
    final hasAppliedCoupon = appliedCoupon != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAppliedCoupon
              ? Colors.green.shade300
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onViewAllCoupons,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasAppliedCoupon
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasAppliedCoupon ? Icons.check_circle : Icons.local_offer,
                      color: hasAppliedCoupon
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasAppliedCoupon ? 'Coupon Applied' : 'Apply Coupon',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!hasAppliedCoupon) ...[
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kBandiwalaYellow,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: kBandiwalaYellow,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasAppliedCoupon) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  if (appliedCoupon!['couponType'] == 'freebie' &&
                      appliedCoupon!['freebieImageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        appliedCoupon!['freebieImageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.redeem,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        appliedCoupon!['couponType'] == 'free_delivery'
                            ? Icons.delivery_dining
                            : Icons.currency_rupee,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.celebration,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Yay!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appliedCoupon!['couponCode'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSavingsText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveCoupon,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.green,
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
    if (appliedCoupon == null) return '';

    final couponType = appliedCoupon!['couponType'] ?? 'discount';
    if (couponType == 'discount') {
      return 'You saved ₹${couponDiscount.toInt()}';
    } else if (couponType == 'free_delivery') {
      return 'Free delivery applied';
    } else if (couponType == 'freebie') {
      final freebieName = appliedCoupon!['freebieName'] ?? 'item';
      return 'You got $freebieName free';
    }
    return '';
  }
}

class PriceBreakdownWidget extends StatelessWidget {
  final double grandTotal;
  final double couponDiscount;
  final Map<String, dynamic>? appliedCoupon;

  const PriceBreakdownWidget({
    super.key,
    required this.grandTotal,
    required this.couponDiscount,
    this.appliedCoupon,
  });

  @override
  Widget build(BuildContext context) {
    final isFreeDelivery =
        appliedCoupon != null && appliedCoupon!['couponType'] == 'free_delivery';
    final delivery = isFreeDelivery ? 0.0 : 30.0;
    final taxes = (grandTotal + delivery) * 0.05;
    final total = grandTotal + delivery + taxes - couponDiscount;

    return Column(
      children: [
        _row('Items total', '₹${grandTotal.toStringAsFixed(0)}'),
        _row(
          'Delivery',
          isFreeDelivery ? 'FREE' : '₹${delivery.toStringAsFixed(0)}',
          strikethrough: isFreeDelivery,
        ),
        _row('Taxes & charges', '₹${taxes.toStringAsFixed(0)}'),
        if (couponDiscount > 0 && appliedCoupon!['couponType'] == 'discount')
          _row(
            'Coupon discount',
            '-₹${couponDiscount.toStringAsFixed(0)}',
            isDiscount: true,
          ),
        Divider(height: 16, color: Colors.grey.shade300),
        _row('To pay', '₹${total.toStringAsFixed(0)}', bold: true),
      ],
    );
  }

  Widget _row(
      String label,
      String value, {
        bool bold = false,
        bool isDiscount = false,
        bool strikethrough = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : null,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : null,
              color: isDiscount ? Colors.green : null,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBandiwalaYellow),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _btn(Icons.remove, () => onQuantityChanged(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 16, color: kBandiwalaYellow),
    );
  }
}
