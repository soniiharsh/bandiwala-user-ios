import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import '../providers/coupons_provider.dart';
import 'orders_page.dart';
import '../widgets/bottom_navigation.dart';
import 'cart_page.dart';
import '../widgets/vendor_card.dart'; // WishlistManager + WishlistVendor
import '../core/theme/theme.dart';

const _kYellow = AppColors.primary;

// ─── Entry widget (keeps bottom nav) ─────────────────────────────────────────

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
      _VendorDetailTab(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      CartPage(onBackToHome: () => setState(() => _currentIndex = 0)),
      const OrdersPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: BandiwalaBottomNavigation(
          currentIndex: _currentIndex,
          onItemSelected: (idx) => setState(() => _currentIndex = idx),
        ),
      ),
    );
  }
}

// ─── Main vendor detail tab ───────────────────────────────────────────────────

class _VendorDetailTab extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final VoidCallback onBackPressed;

  const _VendorDetailTab({
    required this.vendorId,
    required this.vendorName,
    required this.onBackPressed,
  });

  @override
  ConsumerState<_VendorDetailTab> createState() => _VendorDetailTabState();
}

class _VendorDetailTabState extends ConsumerState<_VendorDetailTab> {
  String _heroImageUrl = '';
  bool _isWishlisted = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _checkWishlist();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkWishlist() async {
    final list = await WishlistManager.getWishlist();
    if (mounted) {
      setState(
        () => _isWishlisted = list.any((v) => v.vendorId == widget.vendorId),
      );
    }
  }

  Future<void> _toggleWishlist() async {
    final vendor = ref.read(vendorStreamProvider(widget.vendorId)).valueOrNull;
    final wv = WishlistVendor(
      vendorId: widget.vendorId,
      name: widget.vendorName,
      imageUrl: vendor?.imageUrl ?? _heroImageUrl,
      address: vendor?.address ?? '',
      category: vendor?.category ?? '',
      rating: 4.2,
    );
    await WishlistManager.toggle(wv);
    await _checkWishlist();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchCtrl.text.trim().toLowerCase();
      _applyFilters();
    });
  }

  void _setFilter(String f) {
    setState(() {
      _activeFilter = f;
      _applyFilters();
    });
  }

  void _applyFilters() {
    // filtering is now done inline in build using provider data
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorStreamProvider(widget.vendorId));
    final itemsAsync = ref.watch(vendorItemsStreamProvider(widget.vendorId));
    final couponsAsync = ref.watch(activeCouponsProvider);

    final vendor = vendorAsync.valueOrNull;
    final isVendorOnline = vendor?.isAvailable ?? true;
    final allItems = itemsAsync.valueOrNull ?? [];

    // Show error if items stream failed (e.g. missing Firestore index)
    if (itemsAsync.hasError) {
      debugPrint('vendorItemsStreamProvider error: ${itemsAsync.error}');
    }

    // Seed hero image from vendor or first item
    if (_heroImageUrl.isEmpty) {
      if (vendor?.imageUrl.isNotEmpty == true) {
        _heroImageUrl = vendor!.imageUrl;
      } else if (allItems.isNotEmpty && allItems.first.imageUrl.isNotEmpty) {
        _heroImageUrl = allItems.first.imageUrl;
      }
    }

    // Apply search + filter
    var filtered = allItems;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.category.toLowerCase().contains(_searchQuery) ||
            item.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    if (_activeFilter == 'Veg') {
      filtered = filtered.where((item) => item.isVeg).toList();
    } else if (_activeFilter == 'Non-veg') {
      filtered = filtered.where((item) => !item.isVeg).toList();
    }

    // Coupons applicable to this vendor (all coupons are now app-wide)
    final coupons =
        couponsAsync.valueOrNull?.map((c) => c.toMap()).toList() ?? [];

    final rating = '4.2';
    final deliveryTime = '20-30 mins';
    final address = vendor?.address ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroWithOverlappingCard(
              vendor: vendor,
              isVendorOnline: isVendorOnline,
              rating: rating,
              deliveryTime: deliveryTime,
              address: address,
            ),
          ),
          if (coupons.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: VendorCouponsCarousel(coupons: coupons),
              ),
            ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          _buildItemsGrid(
            allItems: allItems,
            filtered: filtered,
            isVendorOnline: isVendorOnline,
            isLoading: itemsAsync.isLoading,
            hasError: itemsAsync.hasError,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _buildMenuFAB(
        allItems: allItems,
        isVendorOnline: isVendorOnline,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Hero image + vendor card (overlap via Stack, no negative margin) ──────
  Widget _buildHeroWithOverlappingCard({
    required dynamic vendor,
    required bool isVendorOnline,
    required String rating,
    required String deliveryTime,
    required String address,
  }) {
    const double cardOverlap = 28.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  // Hero image
                  Positioned.fill(
                    child: _heroImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _heroImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey.shade300),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.store_mall_directory_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    child: _CircleButton(
                      icon: Icons.chevron_left,
                      onTap: widget.onBackPressed,
                    ),
                  ),
                  // Wishlist heart
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 16,
                    child: _CircleButton(
                      icon: _isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: _isWishlisted ? Colors.red : Colors.black87,
                      onTap: _toggleWishlist,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: cardOverlap),
          ],
        ),

        // ── Vendor info card overlapping hero ─
        Positioned(
          bottom: 0,
          left: 12,
          right: 12,
          child: _buildVendorInfoCard(
            isVendorOnline: isVendorOnline,
            rating: rating,
            deliveryTime: deliveryTime,
            address: address,
          ),
        ),
      ],
    );
  }

  // ── Vendor info card — NO inline coupon ──────────────────────────────────
  Widget _buildVendorInfoCard({
    required bool isVendorOnline,
    required String rating,
    required String deliveryTime,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor name
          Text(
            widget.vendorName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Rating + delivery time
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                '$rating Reviews',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  deliveryTime,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              address,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // ── NO inline coupon here (removed) ──
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: _kYellow, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search for food items',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.mic_rounded, color: _kYellow, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Filter chips — Veg + Non-veg ONLY ────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          _VegChip(
            label: 'Veg',
            isVeg: true,
            isActive: _activeFilter == 'Veg',
            onTap: () => _setFilter(_activeFilter == 'Veg' ? 'All' : 'Veg'),
          ),
          const SizedBox(width: 8),
          _VegChip(
            label: 'Non-veg',
            isVeg: false,
            isActive: _activeFilter == 'Non-veg',
            onTap: () =>
                _setFilter(_activeFilter == 'Non-veg' ? 'All' : 'Non-veg'),
          ),
        ],
      ),
    );
  }

  // ── Items grid ────────────────────────────────────────────────────────────
  Widget _buildItemsGrid({
    required List<dynamic> allItems,
    required List<dynamic> filtered,
    required bool isVendorOnline,
    required bool isLoading,
    bool hasError = false,
  }) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _kYellow)),
        ),
      );
    }
    if (hasError) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load items',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (allItems.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No items found',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 270,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = filtered[index];
          return _ItemCard(
            vendorId: widget.vendorId,
            vendorName: widget.vendorName,
            itemId: item.id,
            name: item.name,
            imageUrl: item.imageUrl,
            category: item.category,
            description: item.description,
            isAvailable: item.isAvailable,
            isVendorOnline: isVendorOnline,
            isVeg: item.isVeg,
            price: item.price,
            rating: 4.2,
            ratingCount: 0,
          );
        }, childCount: filtered.length),
      ),
    );
  }

  // ── Menu FAB ──────────────────────────────────────────────────────────────
  Widget _buildMenuFAB({
    required List<dynamic> allItems,
    required bool isVendorOnline,
  }) {
    return FloatingActionButton.extended(
      onPressed: () =>
          _showMenuSheet(allItems: allItems, isVendorOnline: isVendorOnline),
      backgroundColor: Colors.black87,
      icon: const Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        'Menu',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      elevation: 4,
    );
  }

  void _showMenuSheet({
    required List<dynamic> allItems,
    required bool isVendorOnline,
  }) {
    // Convert Item models to QueryDocumentSnapshot-compatible maps for _MenuSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuSheet(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        items: allItems,
        isVendorOnline: isVendorOnline,
      ),
    );
  }
}

// ─── Circle button (back / heart) ────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}

// ─── Veg / Non-veg chip ───────────────────────────────────────────────────────

class _VegChip extends StatelessWidget {
  final String label;
  final bool isVeg;
  final bool isActive;
  final VoidCallback onTap;

  const _VegChip({
    required this.label,
    required this.isVeg,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isVeg ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.black87 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Colors.white : dotColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : dotColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final String itemId;
  final String name;
  final String imageUrl;
  final String category;
  final String description;
  final bool isAvailable;
  final bool isVendorOnline; // ← NEW: vendor-level gate
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
    this.isVendorOnline = true,
    required this.isVeg,
    required this.price,
    required this.rating,
    required this.ratingCount,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailOverlay(
        vendorId: vendorId,
        vendorName: vendorName,
        itemId: itemId,
        name: name,
        imageUrl: imageUrl,
        category: category,
        description: description,
        isVeg: isVeg,
        price: price,
        rating: rating,
        ratingCount: ratingCount,
        isAvailable: isAvailable,
        isVendorOnline: isVendorOnline, // ← pass real-time status
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = isVeg ? Colors.green.shade600 : Colors.red.shade600;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: IgnorePointer(
        // Block all taps when vendor is offline OR item is unavailable
        ignoring: !isVendorOnline || !isAvailable,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image with overlays ───────────────────────────────
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: Colors.grey.shade200),
                                  errorWidget: (_, __, ___) => Container(
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
                      // Rating badge on image
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: _kYellow,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Info section ──────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dot + category
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: badgeColor,
                                    width: 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Name
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          // Price
                          Text(
                            '₹ ${price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          // ADD / counter
                          _ItemCounter(
                            vendorId: vendorId,
                            vendorName: vendorName,
                            itemId: itemId,
                            itemName: name,
                            price: price,
                            isAvailable: isAvailable,
                            isVendorOnline: isVendorOnline, // ← gate
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Offline overlay ─────────────────────────────────────
            if (!isVendorOnline || !isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: !isVendorOnline
                            ? Colors.deepOrange.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        !isVendorOnline
                            ? '🔴 VENDOR OFFLINE'
                            : '😴 OFFLINE NOW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu bottom sheet ────────────────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final List<dynamic> items;
  final bool isVendorOnline;

  const _MenuSheet({
    required this.vendorId,
    required this.vendorName,
    required this.items,
    this.isVendorOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} items',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final isVeg = item.isVeg as bool;
                  final dotColor = isVeg
                      ? Colors.green.shade600
                      : Colors.red.shade600;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: (item.imageUrl ?? '').isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.restaurant, size: 24),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.restaurant, size: 24),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            border: Border.all(color: dotColor, width: 1.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: dotColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name ?? 'Item',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '₹ ${(item.price ?? 0).toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: _ItemCounter(
                        vendorId: vendorId,
                        vendorName: vendorName,
                        itemId: item.id,
                        itemName: item.name ?? '',
                        price: (item.price ?? 0).toDouble(),
                        isAvailable: item.isAvailable ?? true,
                        isVendorOnline: isVendorOnline,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ProductDetailOverlay(
                          vendorId: vendorId,
                          vendorName: vendorName,
                          itemId: item.id,
                          name: item.name ?? 'Item',
                          imageUrl: item.imageUrl ?? '',
                          category: item.category ?? '',
                          description: item.description ?? '',
                          isVeg: item.isVeg ?? true,
                          price: (item.price ?? 0).toDouble(),
                          rating: 4.2,
                          ratingCount: 0,
                          isAvailable: item.isAvailable ?? true,
                          isVendorOnline: isVendorOnline,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product detail overlay ───────────────────────────────────────────────────
// Fixed layout:
//  • Image floats above the white card (stays on top, never overlaps text)
//  • Text content starts well below the image
//  • Add button + counter pinned to bottom
//  • Sheet height = exactly content height (no extra space, no scroll needed)

class ProductDetailOverlay extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final String itemId;
  final String name;
  final String imageUrl;
  final String category;
  final String description;
  final bool isVeg;
  final double price;
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final bool isVendorOnline; // ← NEW

  const ProductDetailOverlay({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.isVeg,
    required this.price,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    this.isVendorOnline = true,
  });

  @override
  ConsumerState<ProductDetailOverlay> createState() =>
      _ProductDetailOverlayState();
}

class _ProductDetailOverlayState extends ConsumerState<ProductDetailOverlay> {
  int quantity = 1;

  // Image visible height above the white card
  static const double _imageHeight = 180.0;
  // How much of the image overlaps the white card from the top
  static const double _imageOverlap = 80.0;
  // Top padding inside white card so text clears the image
  static const double _cardTopPad = _imageHeight - _imageOverlap + 16;

  @override
  void initState() {
    super.initState();
    _syncQuantity();
  }

  void _syncQuantity() {
    final cart = ref.read(cartProvider);
    final vc = cart.cartByVendor[widget.vendorId];
    if (vc != null) {
      final item = vc.items.firstWhere(
        (i) => i.id == widget.itemId,
        orElse: () => CartItem(id: '', name: '', price: 0, quantity: 0),
      );
      setState(() => quantity = item.quantity > 0 ? item.quantity : 1);
    } else {
      setState(() => quantity = 1);
    }
  }

  void _increment() {
    setState(() => quantity++);
    ref
        .read(cartProvider.notifier)
        .addItem(
          vendorId: widget.vendorId,
          vendorName: widget.vendorName,
          itemId: widget.itemId,
          itemName: widget.name,
          price: widget.price,
        );
  }

  void _decrement() {
    if (quantity > 1) {
      setState(() => quantity--);
      ref
          .read(cartProvider.notifier)
          .updateQuantity(
            vendorId: widget.vendorId,
            itemId: widget.itemId,
            delta: -1,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = widget.isVeg
        ? Colors.green.shade600
        : Colors.red.shade600;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // The white card body content (no image, no bottom button)
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Veg badge + category
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                border: Border.all(color: badgeColor, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(Icons.circle, size: 8, color: badgeColor),
            ),
            const SizedBox(width: 6),
            Text(
              widget.category,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          widget.name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Description
        if (widget.description.isNotEmpty)
          Text(
            widget.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        if (widget.description.isNotEmpty) const SizedBox(height: 14),

        // Rating + price row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.ratingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${widget.ratingCount})',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(),
            Text(
              '₹ ${widget.price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kYellow,
              ),
            ),
          ],
        ),
      ],
    );

    // Bottom action bar (qty stepper + add button)
    // canAdd: both the individual item AND the vendor must be available
    final bool canAdd = widget.isAvailable && widget.isVendorOnline;

    final bottomBar = Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: canAdd ? const Color(0xFFFFF3CD) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: canAdd ? _decrement : () {},
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: canAdd ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                ),
                _StepBtn(icon: Icons.add, onTap: canAdd ? _increment : () {}),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canAdd
                  ? () {
                      final cart = ref.read(cartProvider);
                      final vc = cart.cartByVendor[widget.vendorId];
                      final already =
                          vc?.items
                              .firstWhere(
                                (i) => i.id == widget.itemId,
                                orElse: () => CartItem(
                                  id: '',
                                  name: '',
                                  price: 0,
                                  quantity: 0,
                                ),
                              )
                              .quantity ??
                          0;
                      if (already == 0) {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              vendorId: widget.vendorId,
                              vendorName: widget.vendorName,
                              itemId: widget.itemId,
                              itemName: widget.name,
                              price: widget.price,
                            );
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$quantity × ${widget.name} added'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAdd ? _kYellow : Colors.grey.shade300,
                foregroundColor: canAdd ? Colors.black : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                !widget.isVendorOnline
                    ? '🔴 Vendor Offline'
                    : !widget.isAvailable
                    ? '😴 Item Offline'
                    : 'Total  ₹${(widget.price * quantity).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Use an intrinsic-size bottom sheet so it wraps content exactly
    return _IntrinsicBottomSheet(
      imageHeight: _imageHeight,
      imageOverlap: _imageOverlap,
      cardTopPad: _cardTopPad,
      imageUrl: widget.imageUrl,
      cardContent: cardContent,
      bottomBar: bottomBar,
      onClose: () => Navigator.pop(context),
    );
  }
}

/// Uses a Stack so the image is always painted ON TOP of the white card.
/// Sheet height = visibleImageHeight + card content + bottom bar (no scroll, no empty space).
class _IntrinsicBottomSheet extends StatelessWidget {
  final double imageHeight;
  final double imageOverlap;
  final double cardTopPad;
  final String imageUrl;
  final Widget cardContent;
  final Widget bottomBar;
  final VoidCallback onClose;

  const _IntrinsicBottomSheet({
    required this.imageHeight,
    required this.imageOverlap,
    required this.cardTopPad,
    required this.imageUrl,
    required this.cardContent,
    required this.bottomBar,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleImageHeight = imageHeight - imageOverlap;

    // White card rendered first (lower paint order = behind image)
    final whiteCard = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Transparent spacer — image floats above here
        SizedBox(height: visibleImageHeight),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top padding pushes text below the image overlap
              Padding(
                padding: EdgeInsets.fromLTRB(20, cardTopPad, 20, 20),
                child: cardContent,
              ),
              bottomBar,
            ],
          ),
        ),
      ],
    );

    // Stack: whiteCard FIRST (behind), image + close LAST (on top)
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Layer 1: white card (behind) ────────────────────────────
        whiteCard,

        // ── Layer 2: floating image (on top of white card) ──────────
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: imageHeight,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, size: 48),
                    ),
            ),
          ),
        ),

        // ── Layer 3: close button (topmost) ─────────────────────────
        Positioned(
          top: 8,
          right: 24,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _kYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step button ──────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}

// ─── Item counter (ADD button / stepper on card) ──────────────────────────────

class _ItemCounter extends ConsumerWidget {
  final String vendorId;
  final String vendorName;
  final String itemId;
  final String itemName;
  final double price;
  final bool isAvailable;
  final bool isVendorOnline;

  const _ItemCounter({
    required this.vendorId,
    required this.vendorName,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.isAvailable,
    this.isVendorOnline = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final vc = cart.cartByVendor[vendorId];
    final q =
        vc?.items
            .firstWhere(
              (i) => i.id == itemId,
              orElse: () => CartItem(id: '', name: '', price: 0, quantity: 0),
            )
            .quantity ??
        0;

    void add() => ref
        .read(cartProvider.notifier)
        .addItem(
          vendorId: vendorId,
          vendorName: vendorName,
          itemId: itemId,
          itemName: itemName,
          price: price,
        );

    void change(int d) => ref
        .read(cartProvider.notifier)
        .updateQuantity(vendorId: vendorId, itemId: itemId, delta: d);

    // Hard-block when vendor is offline
    if (!isVendorOnline) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: Colors.deepOrange.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'VENDOR OFFLINE',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange.shade400,
            ),
          ),
        ),
      );
    }
    if (!isAvailable) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'OFFLINE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (q == 0) {
      return SizedBox(
        width: double.infinity,
        height: 34,
        child: OutlinedButton(
          onPressed: add,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black87, width: 1.2),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'ADD',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black87, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => change(-1),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                alignment: Alignment.center,
                child: Icon(
                  q == 1 ? Icons.delete_outline : Icons.remove,
                  size: 16,
                  color: q == 1 ? Colors.red.shade400 : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$q',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => change(1),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                alignment: Alignment.center,
                child: const Icon(Icons.add, size: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // placeholder — replaced belowtate();
}
// ─── Coupons carousel ─────────────────────────────────────────────────────────

class VendorCouponsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> coupons;

  const VendorCouponsCarousel({super.key, required this.coupons});

  @override
  State<VendorCouponsCarousel> createState() => _VendorCouponsCarouselState();
}

class _VendorCouponsCarouselState extends State<VendorCouponsCarousel> {
  final PageController _ctrl = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_ctrl.hasClients && mounted) {
        _page++;
        _ctrl.animateToPage(
          _page,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: PageView.builder(
        controller: _ctrl,
        itemCount: widget.coupons.length * 100,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) {
          final d = widget.coupons[i % widget.coupons.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CouponCard(couponData: d),
          );
        },
      ),
    );
  }
}

// ─── Coupon card ──────────────────────────────────────────────────────────────

class CouponCard extends StatelessWidget {
  final Map<String, dynamic> couponData;

  const CouponCard({super.key, required this.couponData});

  @override
  Widget build(BuildContext context) {
    final code = couponData['couponCode'] ?? 'CODE';
    final type = couponData['couponType'] ?? 'discount';
    final min = (couponData['minAmount'] ?? 0).toDouble();

    String label;
    if (type == 'discount') {
      label = 'Flat ${(couponData['discount'] ?? 0).toInt()}% off';
    } else if (type == 'free_delivery') {
      label = 'Free Delivery';
    } else if (type == 'flat_off') {
      label = '₹${(couponData['discount'] ?? 0).toInt()} off';
    } else {
      label = 'Offer';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'USE $code  |  ABOVE ₹${min.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.2,
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
