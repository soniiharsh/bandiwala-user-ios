import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import '../providers/coupons_provider.dart';
import '../models/coupon.dart';
import '../models/item.dart';
import '../core/theme/theme.dart';
import '../widgets/cart_bar.dart';
import '../widgets/active_order_bar.dart';
import '../widgets/item_customization_sheet.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import '../widgets/vendor_card.dart'; // WishlistManager + WishlistVendor
import '../widgets/skeletons.dart';
import '../core/navigation/app_page_route.dart';

const _kYellow = AppColors.primary;

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
  @override
  Widget build(BuildContext context) {
    return _VendorDetailTab(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
      onBackPressed: () => Navigator.of(context).pop(),
    );
  }
}

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
  String _activeSort = 'None';
  bool _hasShownOfflineSnackbar = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendor = ref
          .read(vendorStreamProvider(widget.vendorId))
          .valueOrNull;
      if (vendor != null && !vendor.isAvailable && !_hasShownOfflineSnackbar) {
        _showOfflineSnackbar();
        _hasShownOfflineSnackbar = true;
      }
    });
  }

  void _showOfflineSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "This vendor is not accepting orders at the moment.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final vendorAsync = ref.watch(vendorStreamProvider(widget.vendorId));
    final itemsAsync = ref.watch(vendorItemsStreamProvider(widget.vendorId));

    final vendor = vendorAsync.valueOrNull;
    final isVendorOnline = vendor?.isAvailable ?? true;
    final allItems = itemsAsync.valueOrNull ?? [];

    if (_heroImageUrl.trim().isEmpty) {
      if (vendor?.imageUrl != null && vendor!.imageUrl.trim().isNotEmpty) {
        _heroImageUrl = vendor.imageUrl.trim();
      } else if (allItems.isNotEmpty &&
          (allItems.first.imageUrl as String?)?.trim().isNotEmpty == true) {
        _heroImageUrl = allItems.first.imageUrl.trim();
      }
    }

    var filtered = allItems;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery) ||
                item.category.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }
    if (_activeFilter == 'Veg') {
      filtered = filtered.where((item) => item.isVeg).toList();
    } else if (_activeFilter == 'Non-veg') {
      filtered = filtered.where((item) => !item.isVeg).toList();
    }

    if (_activeSort == 'LowToHigh') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_activeSort == 'HighToLow') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroWithOverlappingCard(
              isVendorOnline: isVendorOnline,
              rating: "4.2",
              deliveryTime: "20-30 mins",
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchHeaderDelegate(
              searchCtrl: _searchCtrl,
              activeFilter: _activeFilter,
              activeSort: _activeSort,
              onFilterChanged: (f) => setState(() => _activeFilter = f),
              onSortChanged: (s) => setState(() => _activeSort = s),
            ),
          ),
          _buildItemsGrid(
            allItems: allItems,
            filtered: filtered,
            isVendorOnline: isVendorOnline,
            isLoading: itemsAsync.isLoading,
            hasError: itemsAsync.hasError,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActiveOrderBar(
              onViewTap: () {
                Navigator.of(
                  context,
                ).push(AppPageRoute(builder: (_) => const OrdersPage()));
              },
            ),
            CartBar(
              onTap: () {
                Navigator.of(context).push(
                  AppPageRoute(
                    builder: (_) =>
                        CartPage(onBackToHome: () => Navigator.pop(context)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      floatingActionButton: _buildMenuFAB(
        allItems: allItems,
        isVendorOnline: isVendorOnline,
      ),
    );
  }

  Widget _buildHeroWithOverlappingCard({
    required bool isVendorOnline,
    required String rating,
    required String deliveryTime,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double heroHeight = 280.0;
    const double cardOverlap = 60.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _heroImageUrl.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _heroImageUrl.trim(),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade200,
                            ),
                          )
                        : Container(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade200,
                          ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    child: _CircleButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: widget.onBackPressed,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 16,
                    child: _CircleButton(
                      icon: _isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: _isWishlisted
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black87),
                      onTap: _toggleWishlist,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 110),
          ],
        ),
        Positioned(
          top: heroHeight - cardOverlap,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vendorName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(143 Reviews)",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer_outlined,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deliveryTime,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 16),
                _VendorCouponStrip(vendorId: widget.vendorId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsGrid({
    required List<dynamic> allItems,
    required List<dynamic> filtered,
    required bool isVendorOnline,
    required bool isLoading,
    bool hasError = false,
  }) {
    if (isLoading)
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: VendorItemsSkeleton(),
        ),
      );
    if (filtered.isEmpty)
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text("No items found"),
          ),
        ),
      );

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = filtered[index];
          return _ItemCard(
            vendorId: widget.vendorId,
            vendorName: widget.vendorName,
            item: item,
            isVendorOnline: isVendorOnline,
            rating: 4.2,
          );
        }, childCount: filtered.length),
      ),
    );
  }

  Widget _buildMenuFAB({
    required List<dynamic> allItems,
    required bool isVendorOnline,
  }) {
    return FloatingActionButton.extended(
      onPressed: () =>
          _showMenuSheet(allItems: allItems, isVendorOnline: isVendorOnline),
      backgroundColor: Colors.black, // Still black as it's a fixed FAB
      icon: const Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: 18,
      ),
      label: const Text(
        'Menu',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showMenuSheet({
    required List<dynamic> allItems,
    required bool isVendorOnline,
  }) {
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

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchCtrl;
  final String activeFilter;
  final String activeSort;
  final Function(String) onFilterChanged;
  final Function(String) onSortChanged;

  _StickySearchHeaderDelegate({
    required this.searchCtrl,
    required this.activeFilter,
    required this.activeSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  double get minExtent => 140.0;
  @override
  double get maxExtent => 140.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isPinned = shrinkOffset > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: isPinned
            ? [
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [_buildSearchBar(context), _buildFilterChips(context)],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: _kYellow, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search for food items",
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: const Icon(Icons.mic_none_rounded, color: _kYellow),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: onSortChanged,
            color: Theme.of(context).cardColor,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'LowToHigh',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'HighToLow',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(value: 'None', child: Text('Clear Sort')),
            ],
            child: _FilterChip(
              label: activeSort == 'None'
                  ? "Filters"
                  : (activeSort == 'LowToHigh' ? "Price ↑" : "Price ↓"),
              icon: Icons.tune_rounded,
              isActive: activeSort != 'None',
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: "Veg",
            icon: Icons.radio_button_checked,
            iconColor: Colors.green,
            isActive: activeFilter == 'Veg',
            onTap: () => onFilterChanged(activeFilter == 'Veg' ? 'All' : 'Veg'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: "Non-veg",
            icon: Icons.radio_button_checked,
            iconColor: Colors.red,
            isActive: activeFilter == 'Non-veg',
            onTap: () =>
                onFilterChanged(activeFilter == 'Non-veg' ? 'All' : 'Non-veg'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: "Best Seller",
            icon: Icons.verified,
            iconColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.activeFilter != activeFilter ||
        oldDelegate.activeSort != activeSort ||
        oldDelegate.searchCtrl != searchCtrl;
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: iconColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isActive;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.iconColor,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? _kYellow : Colors.black)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? (isDark ? Colors.black87 : Colors.white)
                  : (iconColor ??
                        (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? (isDark ? Colors.black87 : Colors.white)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (label.contains("Filters") || label.contains("Price")) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isActive
                    ? (isDark ? Colors.black87 : Colors.white)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String vendorId, vendorName;
  final Item item;
  final bool isVendorOnline;
  final double rating;

  const _ItemCard({
    required this.vendorId,
    required this.vendorName,
    required this.item,
    required this.isVendorOnline,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canAdd = item.isAvailable && isVendorOnline;

    return GestureDetector(
      onTap: () => _showProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: item.imageUrl.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl.trim(),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                            ),
                          )
                        : Container(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.green, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Show customizable badge
                if (_hasCustomizations)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kYellow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Customizable',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: item.isVeg ? Colors.green : Colors.red,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${item.price.toInt()}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        _AddButton(
                          vendorId: vendorId,
                          vendorName: vendorName,
                          item: item,
                          isAvailable: canAdd,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasCustomizations => item.hasCustomizations;

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailOverlay(
        vendorId: vendorId,
        vendorName: vendorName,
        item: item,
        rating: rating,
        ratingCount: 143,
        isVendorOnline: isVendorOnline,
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  final String vendorId, vendorName;
  final Item item;
  final bool isAvailable;
  const _AddButton({
    required this.vendorId,
    required this.vendorName,
    required this.item,
    required this.isAvailable,
  });

  bool get _hasCustomizations => item.hasCustomizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty =
        cart.cartByVendor[vendorId]?.items
            .where((i) => i.id == item.id)
            .fold(0, (sum, i) => sum + i.quantity) ??
        0;

    if (qty > 0) {
      return Container(
        height: 28,
        width: 64,
        decoration: BoxDecoration(
          color: _kYellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => ref
                  .read(cartProvider.notifier)
                  .updateQuantity(
                    vendorId: vendorId,
                    itemId: item.id,
                    delta: -1,
                  ),
              child: const Icon(Icons.remove, size: 12, color: Colors.white),
            ),
            Text(
              "$qty",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_hasCustomizations) {
                  showItemCustomizationSheet(
                    context: context,
                    vendorId: vendorId,
                    vendorName: vendorName,
                    item: item,
                  );
                } else {
                  ref
                      .read(cartProvider.notifier)
                      .addItem(
                        vendorId: vendorId,
                        vendorName: vendorName,
                        itemId: item.id,
                        itemName: item.name,
                        price: item.price,
                      );
                }
              },
              child: const Icon(Icons.add, size: 12, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
              if (_hasCustomizations) {
                showItemCustomizationSheet(
                  context: context,
                  vendorId: vendorId,
                  vendorName: vendorName,
                  item: item,
                );
              } else {
                ref
                    .read(cartProvider.notifier)
                    .addItem(
                      vendorId: vendorId,
                      vendorName: vendorName,
                      itemId: item.id,
                      itemName: item.name,
                      price: item.price,
                    );
              }
            }
          : null,
      child: Container(
        height: 28,
        width: 64,
        decoration: BoxDecoration(
          color: isAvailable
              ? (isDark ? Colors.transparent : Colors.white)
              : Colors.transparent,
          border: Border.all(
            color: isAvailable
                ? _kYellow
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          "ADD",
          style: TextStyle(
            color: isAvailable
                ? _kYellow
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade400),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _MenuSheet extends StatelessWidget {
  final String vendorId, vendorName;
  final List<dynamic> items;
  final bool isVendorOnline;
  const _MenuSheet({
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.isVendorOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: items.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(
                    items[i].name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "₹${items[i].price}",
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: _AddButton(
                    vendorId: vendorId,
                    vendorName: vendorName,
                    item: items[i],
                    isAvailable: isVendorOnline && items[i].isAvailable,
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

class ProductDetailOverlay extends ConsumerWidget {
  final String vendorId, vendorName;
  final Item item;
  final double rating;
  final int ratingCount;
  final bool isVendorOnline;

  const ProductDetailOverlay({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.item,
    required this.rating,
    required this.ratingCount,
    required this.isVendorOnline,
  });

  bool get _hasCustomizations => item.hasCustomizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canAdd = item.isAvailable && isVendorOnline;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: item.isVeg ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                item.category,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              if (_hasCustomizations) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Customizable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kYellow,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${item.price.toInt()}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _kYellow,
                ),
              ),
              _AddButton(
                vendorId: vendorId,
                vendorName: vendorName,
                item: item,
                isAvailable: canAdd,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Vendor Coupon Strip ──────────────────────────────────────────────────────

class _VendorCouponStrip extends ConsumerWidget {
  final String vendorId;
  const _VendorCouponStrip({required this.vendorId});

  String _couponLabel(Coupon c) {
    switch (c.couponType) {
      case 'free_delivery':
        return 'FREE delivery';
      case 'flat_off':
        return '₹${c.discount.toInt()} off on ₹${c.minAmount.toInt()}+';
      case 'discount':
        final cap = c.maxDiscountableAmount > 0
            ? ' upto ₹${c.maxDiscountableAmount}'
            : '';
        return '${c.discount.toInt()}%$cap off';
      default:
        return c.couponCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(vendorCouponsProvider(vendorId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return couponsAsync.when(
      loading: () => const SizedBox(height: 28),
      error: (_, __) => const SizedBox.shrink(),
      data: (coupons) {
        if (coupons.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = coupons[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.teal.shade900.withValues(alpha: 0.5)
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.teal.shade700 : Colors.teal.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      size: 12,
                      color: isDark
                          ? Colors.teal.shade300
                          : Colors.teal.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _couponLabel(c),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.teal.shade300
                            : Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
