// vendor_items_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'orders.dart';
import 'bottom_navigation.dart';
import 'cart_screen.dart';
import 'help_screen.dart';
import 'cart_store.dart';
import 'home_page.dart'; // WishlistManager + WishlistVendor

const _kYellow = Color(0xFFFFC107);

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
      CartScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
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

class _VendorDetailTab extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final VoidCallback onBackPressed;

  const _VendorDetailTab({
    required this.vendorId,
    required this.vendorName,
    required this.onBackPressed,
  });

  @override
  State<_VendorDetailTab> createState() => _VendorDetailTabState();
}

class _VendorDetailTabState extends State<_VendorDetailTab> {
  Map<String, dynamic>? _vendorMeta;
  List<QueryDocumentSnapshot> _allDocs = [];
  List<QueryDocumentSnapshot> _filteredDocs = [];
  String _heroImageUrl = '';
  bool _isWishlisted = false;
  bool _loadingMeta = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  List<Map<String, dynamic>> _coupons = [];

  StreamSubscription? _itemsSub;
  StreamSubscription? _couponsSub;

  @override
  void initState() {
    super.initState();
    _loadVendorMeta();
    _subscribeItems();
    _subscribeCoupons();
    _checkWishlist();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _itemsSub?.cancel();
    _couponsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadVendorMeta() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.vendorId)
          .get();
      if (mounted) {
        setState(() {
          _vendorMeta = doc.data();
          _loadingMeta = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  void _subscribeItems() {
    _itemsSub = FirebaseFirestore.instance
        .collection('items')
        .doc(widget.vendorId)
        .collection('items')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _allDocs = snap.docs;
            if (_heroImageUrl.isEmpty && snap.docs.isNotEmpty) {
              final firstData = snap.docs.first.data() as Map<String, dynamic>;
              _heroImageUrl = firstData['imageUrl'] ?? '';
            }
            _applyFilters();
          });
        });
  }

  void _subscribeCoupons() {
    _couponsSub = FirebaseFirestore.instance
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final applicable = snap.docs
              .where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                if (d['isWholeApp'] == true) return true;
                final ids = d['vendorIds'] as List<dynamic>? ?? [];
                return ids.any(
                  (id) =>
                      id.toString().trim() == widget.vendorId.toString().trim(),
                );
              })
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          setState(() => _coupons = applicable);
        });
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
    final wv = WishlistVendor(
      vendorId: widget.vendorId,
      name: widget.vendorName,
      imageUrl: _heroImageUrl,
      address: _vendorMeta?['address'] ?? '',
      category: _vendorMeta?['category'] ?? '',
      rating: (_vendorMeta?['rating'] ?? 4.2).toDouble(),
    );
    await WishlistManager.toggleWishlist(wv);
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
    List<QueryDocumentSnapshot> result = List.of(_allDocs);

    if (_searchQuery.isNotEmpty) {
      result = result.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final name = (d['name'] ?? '').toString().toLowerCase();
        final cat = (d['category'] ?? '').toString().toLowerCase();
        final desc = (d['description'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) ||
            cat.contains(_searchQuery) ||
            desc.contains(_searchQuery);
      }).toList();
    }

    if (_activeFilter == 'Veg') {
      result = result
          .where((doc) => (doc.data() as Map<String, dynamic>)['isVeg'] == true)
          .toList();
    } else if (_activeFilter == 'Non-veg') {
      result = result
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['isVeg'] == false,
          )
          .toList();
    }

    _filteredDocs = result;
  }

  String get _rating =>
      (_vendorMeta?['rating'] ?? 4.2).toDouble().toStringAsFixed(1);
  String get _ratingCount => ((_vendorMeta?['ratingCount'] ?? 143)).toString();
  String get _deliveryTime => _vendorMeta?['deliveryTime'] ?? '20-30 mins';
  String get _address => _vendorMeta?['address'] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Hero + overlapping vendor card combined ───────────────────
          SliverToBoxAdapter(child: _buildHeroWithOverlappingCard()),

          // ── Coupons carousel ─────────────────────────────────────────
          if (_coupons.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: VendorCouponsCarousel(coupons: _coupons),
              ),
            ),

          // ── Search bar ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSearchBar()),

          // ── Filter chips (Veg + Non-veg only) ───────────────────────
          SliverToBoxAdapter(child: _buildFilterChips()),

          // ── Items grid ───────────────────────────────────────────────
          _buildItemsGrid(),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _buildMenuFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Hero image + vendor card (overlap via Stack, no negative margin) ──────
  Widget _buildHeroWithOverlappingCard() {
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
          child: _buildVendorInfoCard(),
        ),
      ],
    );
  }

  // ── Vendor info card — NO inline coupon ──────────────────────────────────
  Widget _buildVendorInfoCard() {
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
                '$_rating ($_ratingCount Reviews)',
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
                  _deliveryTime,
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
          if (_address.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _address,
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
  Widget _buildItemsGrid() {
    if (_allDocs.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _kYellow)),
        ),
      );
    }
    if (_filteredDocs.isEmpty) {
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
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = _filteredDocs[index];
          final d = doc.data() as Map<String, dynamic>;
          return _ItemCard(
            vendorId: widget.vendorId,
            vendorName: widget.vendorName,
            itemId: doc.id,
            name: d['name'] ?? 'Item',
            imageUrl: d['imageUrl'] ?? '',
            category: d['category'] ?? '',
            description: d['description'] ?? '',
            isAvailable: d['isAvailable'] ?? true,
            isVeg: d['isVeg'] ?? true,
            price: (d['price'] ?? 0).toDouble(),
            rating: (d['rating'] ?? 4.2).toDouble(),
            ratingCount: (d['ratingCount'] ?? 0).toInt(),
          );
        }, childCount: _filteredDocs.length),
      ),
    );
  }

  // ── Menu FAB ──────────────────────────────────────────────────────────────
  Widget _buildMenuFAB() {
    return FloatingActionButton.extended(
      onPressed: _showMenuSheet,
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

  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuSheet(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        allDocs: _allDocs,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = isVeg ? Colors.green.shade600 : Colors.red.shade600;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.55,
        child: Container(
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
                  // Unavailable overlay
                  if (!isAvailable)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Unavailable',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
                              border: Border.all(color: badgeColor, width: 1.2),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu bottom sheet ────────────────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final List<QueryDocumentSnapshot> allDocs;

  const _MenuSheet({
    required this.vendorId,
    required this.vendorName,
    required this.allDocs,
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
                    '${allDocs.length} items',
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
                itemCount: allDocs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70),
                itemBuilder: (ctx, i) {
                  final d = allDocs[i].data() as Map<String, dynamic>;
                  final isVeg = d['isVeg'] ?? true;
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
                        child: (d['imageUrl'] ?? '').isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: d['imageUrl'],
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
                            d['name'] ?? 'Item',
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
                      '₹ ${(d['price'] ?? 0).toInt()}',
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
                        itemId: allDocs[i].id,
                        itemName: d['name'] ?? '',
                        price: (d['price'] ?? 0).toDouble(),
                        isAvailable: d['isAvailable'] ?? true,
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
                          itemId: allDocs[i].id,
                          name: d['name'] ?? 'Item',
                          imageUrl: d['imageUrl'] ?? '',
                          category: d['category'] ?? '',
                          description: d['description'] ?? '',
                          isVeg: d['isVeg'] ?? true,
                          price: (d['price'] ?? 0).toDouble(),
                          rating: (d['rating'] ?? 4.2).toDouble(),
                          ratingCount: (d['ratingCount'] ?? 0).toInt(),
                          isAvailable: d['isAvailable'] ?? true,
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

class ProductDetailOverlay extends StatefulWidget {
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
  });

  @override
  State<ProductDetailOverlay> createState() => _ProductDetailOverlayState();
}

class _ProductDetailOverlayState extends State<ProductDetailOverlay> {
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
    cartStore.addListener(_onCartChanged);
    _syncQuantity();
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) _syncQuantity();
  }

  void _syncQuantity() {
    final vc = cartStore.cartByVendor[widget.vendorId];
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
    cartStore.addItem(
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
      cartStore.updateQuantity(
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
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _StepBtn(icon: Icons.remove, onTap: _decrement),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepBtn(icon: Icons.add, onTap: _increment),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.isAvailable
                  ? () {
                      final vc = cartStore.cartByVendor[widget.vendorId];
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
                        cartStore.addItem(
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
                backgroundColor: _kYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.isAvailable
                    ? 'Total  ₹${(widget.price * quantity).toStringAsFixed(0)}'
                    : 'UNAVAILABLE',
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
    cartStore.addListener(_onChange);
  }

  @override
  void dispose() {
    cartStore.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  int get _qty {
    final vc = cartStore.cartByVendor[widget.vendorId];
    if (vc == null) return 0;
    return vc.items
        .firstWhere(
          (i) => i.id == widget.itemId,
          orElse: () => CartItem(id: '', name: '', price: 0, quantity: 0),
        )
        .quantity;
  }

  void _add() => cartStore.addItem(
    vendorId: widget.vendorId,
    vendorName: widget.vendorName,
    itemId: widget.itemId,
    itemName: widget.itemName,
    price: widget.price,
  );

  void _change(int d) => cartStore.updateQuantity(
    vendorId: widget.vendorId,
    itemId: widget.itemId,
    delta: d,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.isAvailable) {
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
            'UNAVAILABLE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final q = _qty;

    if (q == 0) {
      return SizedBox(
        width: double.infinity,
        height: 34,
        child: OutlinedButton(
          onPressed: _add,
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

    // ✅ Fixed counter: buttons are fixed size, number is flexible center
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
            // ── Minus button ─────────────────────────────────────
            GestureDetector(
              onTap: () => _change(-1),
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

            // ── Quantity number — takes remaining space, never overflows ──
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

            // ── Plus button ──────────────────────────────────────
            GestureDetector(
              onTap: () => _change(1),
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
      label = 'Flat ${(couponData['discountAmount'] ?? 0).toInt()}% off';
    } else if (type == 'free_delivery') {
      label = 'Free Delivery';
    } else {
      label = couponData['freebieName'] ?? 'Free Item';
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
