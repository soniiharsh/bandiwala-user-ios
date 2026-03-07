// promotional.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'vendor_items_page.dart';
import 'home_page.dart'; // ← WishlistManager + WishlistVendor

const kBandiwalaYellow = Color(0xFFFFC107);

// ─── PromotionalBanner ────────────────────────────────────────────────────────

class PromotionalBanner extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const PromotionalBanner({super.key, this.onCategorySelected});

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<PromotionData> _promotions = [];
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    if (_hasLoaded) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .orderBy('order')
          .get();

      final activePromotions = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .map((doc) => PromotionData.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _promotions = activePromotions;
          _isLoading = false;
          _hasLoaded = true;
        });
        if (_promotions.isNotEmpty) _startAutoScroll();
      }
    } catch (e) {
      debugPrint('Error loading promotions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _promotions.isEmpty) {
        return;
      }
      _currentPage = (_currentPage + 1) % _promotions.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner Carousel ──────────────────────────────────────────────
        if (_isLoading)
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: kBandiwalaYellow,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_promotions.isNotEmpty) ...[
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _promotions.length,
              itemBuilder: (_, i) =>
                  _PromotionalImageCard(promotion: _promotions[i]),
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promotions.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? kBandiwalaYellow
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Recommended / Favourites tabs + side-scroll vendor strip ─────
        RecommendedVendorsStrip(onCategorySelected: widget.onCategorySelected),

        const SizedBox(height: 28),

        // ── What's on your mind ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FoodCategoryCarousel(
            onCategorySelected: widget.onCategorySelected,
          ),
        ),
      ],
    );
  }
}

// ─── Vendor data model ────────────────────────────────────────────────────────

class _VendorData {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final String deliveryTime;
  final String discount;
  final String maxDiscount;
  final bool isAvailable;

  const _VendorData({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.discount,
    required this.maxDiscount,
    required this.isAvailable,
  });

  factory _VendorData.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _VendorData(
      id: d['id'] ?? doc.id,
      name: d['name'] ?? 'Vendor',
      category: d['category'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      rating: (d['rating'] ?? 4.2).toDouble(),
      deliveryTime: d['deliveryTime'] ?? '20-30 min',
      discount: d['discount'] ?? '',
      maxDiscount: d['maxDiscount'] ?? '',
      isAvailable: d['isAvailable'] ?? true,
    );
  }
}

// ─── RecommendedVendorsStrip ──────────────────────────────────────────────────

class RecommendedVendorsStrip extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const RecommendedVendorsStrip({super.key, this.onCategorySelected});

  @override
  State<RecommendedVendorsStrip> createState() =>
      _RecommendedVendorsStripState();
}

class _RecommendedVendorsStripState extends State<RecommendedVendorsStrip>
    with AutomaticKeepAliveClientMixin, RouteAware {
  int _activeTab = 0;
  List<_VendorData> _allVendors = [];
  Set<String> _wishlistIds = {};
  bool _isLoading = true;
  bool _hasLoaded = false;

  // A single app-wide RouteObserver — add this to MaterialApp.navigatorObservers
  static final routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called automatically when user pops back to this screen
  @override
  void didPopNext() => _refreshWishlist();

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadVendors() async {
    if (_hasLoaded) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true)
          .get();

      final List<_VendorData> vendors = snap.docs
          .map((doc) => _VendorData.fromDoc(doc))
          .toList();

      // Sort by availability (Available vendors first)
      vendors.sort((a, b) {
        if (a.isAvailable != b.isAvailable) {
          return a.isAvailable ? -1 : 1;
        }
        return 0; // Maintain createdAt descending order
      });
      final ids = await _fetchWishlistIds();

      if (mounted) {
        setState(() {
          _allVendors = vendors;
          _wishlistIds = ids;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor strip: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  /// Light refresh — just reload wishlist IDs, no full vendor re-fetch
  Future<void> _refreshWishlist() async {
    final ids = await _fetchWishlistIds();
    if (mounted) setState(() => _wishlistIds = ids);
  }

  Future<Set<String>> _fetchWishlistIds() async {
    final list = await WishlistManager.getWishlist();
    return list.map((v) => v.vendorId).toSet();
  }

  // ── Wishlist toggle ───────────────────────────────────────────────────────

  Future<void> _toggleWishlist(_VendorData vendor) async {
    final wv = WishlistVendor(
      vendorId: vendor.id,
      name: vendor.name,
      imageUrl: vendor.imageUrl,
      address: '',
      category: vendor.category,
      rating: vendor.rating,
    );
    await WishlistManager.toggleWishlist(wv);
    await _refreshWishlist();

    if (!mounted) return;
    final isNowIn = _wishlistIds.contains(vendor.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowIn
              ? '${vendor.name} added to wishlist'
              : '${vendor.name} removed from wishlist',
        ),
        backgroundColor: isNowIn ? Colors.green : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Display helpers ───────────────────────────────────────────────────────

  List<_VendorData> get _displayed {
    if (_activeTab == 1) {
      return _allVendors.where((v) => _wishlistIds.contains(v.id)).toList();
    }
    return _allVendors;
  }

  void _openVendor(BuildContext context, _VendorData vendor) {
    if (!vendor.isAvailable) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VendorItemsPage(vendorId: vendor.id, vendorName: vendor.name),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tabs — centred ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tab('Recommended', 0),
              const SizedBox(width: 10),
              _tab(
                'Favourites',
                1,
                icon: _activeTab == 1
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Horizontal vendor scroll ────────────────────────────────────
        SizedBox(
          height: 215,
          child: _isLoading
              ? _buildShimmer()
              : _displayed.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _activeTab == 1
                            ? Icons.favorite_border_rounded
                            : Icons.store_outlined,
                        size: 42,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _activeTab == 1
                            ? 'No favourites yet\nTap ♥ on any vendor to save'
                            : 'No vendors available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _displayed.length,
                  itemBuilder: (ctx, i) {
                    final v = _displayed[i];
                    return _VendorMiniCard(
                      vendor: v,
                      isFavourite: _wishlistIds.contains(v.id),
                      onFavouriteTap: () => _toggleWishlist(v),
                      onTap: () => _openVendor(ctx, v),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tab(String label, int index, {IconData? icon}) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.black87 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? (index == 1 ? Colors.red.shade300 : Colors.white)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 115,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _VendorMiniCard ──────────────────────────────────────────────────────────

class _VendorMiniCard extends StatelessWidget {
  final _VendorData vendor;
  final bool isFavourite;
  final VoidCallback onFavouriteTap;
  final VoidCallback onTap;

  const _VendorMiniCard({
    required this.vendor,
    required this.isFavourite,
    required this.onFavouriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = vendor.discount.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: vendor.isAvailable ? 1.0 : 0.55,
        child: Container(
          width: 175,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image + overlays ──────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: vendor.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: vendor.imageUrl,
                            width: 175,
                            height: 115,
                            fit: BoxFit.cover,
                            memCacheWidth: 350,
                            memCacheHeight: 230,
                            maxWidthDiskCache: 350,
                            maxHeightDiskCache: 230,
                            placeholder: (_, __) => Container(
                              width: 175,
                              height: 115,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kBandiwalaYellow,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 175,
                              height: 115,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.store,
                                size: 32,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 175,
                            height: 115,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.store,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  // Discount badge — bottom-left
                  if (hasDiscount)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1BA672),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${vendor.discount} OFF',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (vendor.maxDiscount.isNotEmpty)
                              Text(
                                'up to ₹${vendor.maxDiscount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Favourite heart — top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onFavouriteTap,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavourite
                              ? Colors.red
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                  // Unavailable overlay
                  if (!vendor.isAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
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
                ],
              ),

              // ── Info section ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (vendor.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        vendor.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        // Rating chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            vendor.deliveryTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
}

// ─── FoodCategoryCarousel ─────────────────────────────────────────────────────

class FoodCategoryCarousel extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const FoodCategoryCarousel({super.key, this.onCategorySelected});

  @override
  State<FoodCategoryCarousel> createState() => _FoodCategoryCarouselState();
}

class _FoodCategoryCarouselState extends State<FoodCategoryCarousel>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  List<FoodCategory> _categories = [];
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  final FoodCategory _allCategory = FoodCategory(
    name: 'All',
    imageUrl: 'assets/images/Bajji pakoda.png',
    order: -1,
    isActive: true,
    isLocal: true,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_hasLoaded) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_categories')
          .orderBy('order')
          .get();

      final firebaseCategories = snapshot.docs
          .map((doc) => FoodCategory.fromFirestore(doc))
          .where((c) => c.isActive)
          .toList();

      if (mounted) {
        setState(() {
          _categories = [_allCategory, ...firebaseCategories];
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading food categories: $e');
      if (mounted) {
        setState(() {
          _categories = [_allCategory];
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedIndex = index);

    const double itemWidth = 75.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double target =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }

    final name = _categories[index].name;
    widget.onCategorySelected?.call(name == 'All' ? '' : name);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's on your mind?",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: kBandiwalaYellow,
                    strokeWidth: 2,
                  ),
                )
              : _categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onCategoryTap(index),
                      child: _FoodCategoryCard(
                        category: _categories[index],
                        isSelected: index == _selectedIndex,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── _FoodCategoryCard ────────────────────────────────────────────────────────

class _FoodCategoryCard extends StatelessWidget {
  final FoodCategory category;
  final bool isSelected;

  const _FoodCategoryCard({required this.category, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: ClipOval(
              child: category.isLocal
                  ? Image.asset(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 28,
                        color: Colors.grey,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      memCacheHeight: 128,
                      maxWidthDiskCache: 128,
                      maxHeightDiskCache: 128,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBandiwalaYellow,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 28,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Column(
            children: [
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSelected ? 11.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 28 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: kBandiwalaYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class FoodCategory {
  final String name;
  final String imageUrl;
  final int order;
  final bool isActive;
  final bool isLocal;

  FoodCategory({
    required this.name,
    required this.imageUrl,
    required this.order,
    required this.isActive,
    this.isLocal = false,
  });

  factory FoodCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodCategory(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      isLocal: false,
    );
  }
}

class PromotionData {
  final String id;
  final String imageUrl;
  final int order;
  final bool isActive;

  PromotionData({
    required this.id,
    required this.imageUrl,
    required this.order,
    required this.isActive,
  });

  factory PromotionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionData(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}

// ─── _PromotionalImageCard ────────────────────────────────────────────────────

class _PromotionalImageCard extends StatelessWidget {
  final PromotionData promotion;

  const _PromotionalImageCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: promotion.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: promotion.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                memCacheWidth: 1200,
                memCacheHeight: 400,
                maxWidthDiskCache: 1200,
                maxHeightDiskCache: 400,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: kBandiwalaYellow,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 46,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 46,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
      ),
    );
  }
}
