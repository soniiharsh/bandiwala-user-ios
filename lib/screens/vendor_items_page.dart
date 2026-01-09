import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'top_bar.dart';
import 'bottom_navigation.dart';
import 'cart_screen.dart';
import 'help_screen.dart';
import 'cart_store.dart';

class VendorItemsPage extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorItemsPage({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorItemsPage> createState() => _VendorItemsPageState();
}

class _VendorItemsPageState extends State<VendorItemsPage> {
  int _currentIndex = 0;

  void _handleBackPress() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _VendorItemsTab(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      CartScreen(
        onBackToHome: () {
          setState(() => _currentIndex = 0);
        },
      ),
      const HelpScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BandiwalaBottomNavigation(
          currentIndex: _currentIndex,
          onItemSelected: (idx) {
            setState(() => _currentIndex = idx);
          },
        ),
      ),
    );
  }
}

class _VendorItemsTab extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final VoidCallback onBackPressed;

  const _VendorItemsTab({
    required this.vendorId,
    required this.vendorName,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Custom top bar with back button (FIXED - doesn't scroll)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    vendorName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ✅ SCROLLABLE CONTENT: Coupons + Items together
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .doc(vendorId)
                  .collection('items')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, itemsSnapshot) {
                if (itemsSnapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = itemsSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('coupons')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, couponsSnapshot) {
                    List<Map<String, dynamic>> applicableCoupons = [];

                    if (couponsSnapshot.hasData) {
                      final allCoupons = couponsSnapshot.data!.docs;

                      applicableCoupons = allCoupons.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isWholeApp = data['isWholeApp'] ?? false;

                        if (isWholeApp) {
                          return true;
                        }

                        final vendorIds = data['vendorIds'] as List<dynamic>? ?? [];
                        return vendorIds.any((id) {
                          final idString = id.toString().trim();
                          final phoneString = vendorId.toString().trim();
                          return idString == phoneString;
                        });
                      }).map((doc) => doc.data() as Map<String, dynamic>).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No items available for this vendor'),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        // ✅ COUPONS CAROUSEL (scrolls with items)
                        if (applicableCoupons.isNotEmpty)
                          SliverToBoxAdapter(
                            child: VendorCouponsCarousel(
                              coupons: applicableCoupons,
                            ),
                          ),

                        // ✅ ITEMS GRID
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.7,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                final String itemId = doc.id;
                                final String name = data['name'] ?? 'Item';
                                final String imageUrl = data['imageUrl'] ?? '';
                                final String category = data['category'] ?? '';
                                final String description = data['description'] ?? '';
                                final bool isAvailable = data['isAvailable'] ?? true;
                                final bool isVeg = data['isVeg'] ?? true;
                                final num price = data['price'] ?? 0;
                                final double rating = (data['rating'] ?? 4.2).toDouble();
                                final int ratingCount = (data['ratingCount'] ?? 0).toInt();

                                return _ItemCard(
                                  vendorId: vendorId,
                                  vendorName: vendorName,
                                  itemId: itemId,
                                  name: name,
                                  imageUrl: imageUrl,
                                  category: category,
                                  description: description,
                                  isAvailable: isAvailable,
                                  isVeg: isVeg,
                                  price: price.toDouble(),
                                  rating: rating,
                                  ratingCount: ratingCount,
                                );
                              },
                              childCount: docs.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ HORIZONTAL SCROLLING COUPON CAROUSEL (now part of the main scroll)
class VendorCouponsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> coupons;

  const VendorCouponsCarousel({super.key, required this.coupons});

  @override
  State<VendorCouponsCarousel> createState() => _VendorCouponsCarouselState();
}

class _VendorCouponsCarouselState extends State<VendorCouponsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && mounted) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.coupons.length * 100,
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              _currentPage = index;
            });
          }
        },
        itemBuilder: (context, index) {
          final actualIndex = index % widget.coupons.length;
          final couponData = widget.coupons[actualIndex];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CouponCard(couponData: couponData),
          );
        },
      ),
    );
  }
}

// ✅ WHITE BACKGROUND WITH BLACK TEXT
class CouponCard extends StatelessWidget {
  final Map<String, dynamic> couponData;

  const CouponCard({super.key, required this.couponData});

  @override
  Widget build(BuildContext context) {
    final couponCode = couponData['couponCode'] ?? 'CODE';
    final couponType = couponData['couponType'] ?? 'discount';
    final minAmount = (couponData['minAmount'] ?? 0).toDouble();

    String discountText = '';
    String subtitle = 'ABOVE ₹${minAmount.toInt()}';

    if (couponType == 'discount') {
      final discount = (couponData['discountAmount'] ?? 0).toDouble();
      discountText = 'Flat ${discount.toInt()}% off';
    } else if (couponType == 'free_delivery') {
      discountText = 'Free Delivery';
      subtitle = 'ABOVE ₹${minAmount.toInt()}';
    } else if (couponType == 'freebie') {
      discountText = couponData['freebieName'] ?? 'Free Item';
      subtitle = 'ABOVE ₹${minAmount.toInt()}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Left: Yellow badge with % icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // ✅ Middle: Black text on white background
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  discountText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'USE $couponCode  |  $subtitle',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final String itemId;
  final String name;
  final String imageUrl;
  final String category;
  final String description;
  final bool isAvailable;
  final bool isVeg;
  final double price;
  final double rating;
  final int ratingCount;

  const _ItemCard({
    required this.vendorId,
    required this.vendorName,
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.isAvailable,
    required this.isVeg,
    required this.price,
    required this.rating,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isVeg ? Colors.green.shade600 : Colors.red.shade600;

    return IgnorePointer(
      ignoring: !isAvailable,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final imageHeight = cardWidth * 0.65;
          final fontSize = cardWidth * 0.065;

          return Card(
            color: Colors.white,
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.restaurant),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.restaurant),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(cardWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: badgeColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize * 0.7,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: cardWidth * 0.015),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          SizedBox(height: cardWidth * 0.01),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSize * 0.7,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        SizedBox(height: cardWidth * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: fontSize * 0.8,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: fontSize * 0.8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  if (ratingCount > 0) ...[
                                    const SizedBox(width: 2),
                                    Text(
                                      '($ratingCount)',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.65,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _ItemCounter(
                          vendorId: vendorId,
                          vendorName: vendorName,
                          itemId: itemId,
                          itemName: name,
                          price: price,
                          isAvailable: isAvailable,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemCounter extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String itemId;
  final String itemName;
  final double price;
  final bool isAvailable;

  const _ItemCounter({
    required this.vendorId,
    required this.vendorName,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.isAvailable,
  });

  @override
  State<_ItemCounter> createState() => _ItemCounterState();
}

class _ItemCounterState extends State<_ItemCounter> {
  @override
  void initState() {
    super.initState();
    cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _currentQty {
    final vendorCart = cartStore.cartByVendor[widget.vendorId];
    if (vendorCart == null) return 0;

    final item = vendorCart.items.firstWhere(
          (item) => item.id == widget.itemId,
      orElse: () => CartItem(
        id: '',
        name: '',
        price: 0,
        quantity: 0,
      ),
    );

    return item.quantity;
  }

  void _addFirst() {
    cartStore.addItem(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
      itemId: widget.itemId,
      itemName: widget.itemName,
      price: widget.price,
    );
  }

  void _change(int delta) {
    cartStore.updateQuantity(
      vendorId: widget.vendorId,
      itemId: widget.itemId,
      delta: delta,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQty = _currentQty;

    if (!widget.isAvailable) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'UNAVAILABLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (currentQty == 0) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton(
          onPressed: _addFirst,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: Colors.black87,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'ADD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black87,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _change(-1),
            icon: const Icon(
              Icons.remove,
              size: 16,
              color: Colors.black87,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
          Text(
            '$currentQty',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => _change(1),
            icon: const Icon(
              Icons.add,
              size: 16,
              color: Colors.black87,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
        ],
      ),
    );
  }
}
