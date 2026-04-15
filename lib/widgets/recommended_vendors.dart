import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vendor.dart';
import '../screens/vendor_items_page.dart';
import '../providers/vendors_provider.dart';
import '../widgets/vendor_card.dart' show WishlistManager, WishlistVendor;
import '../core/navigation/app_page_route.dart';
import 'skeletons.dart';

class RecommendedVendorsStrip extends StatefulWidget {
  const RecommendedVendorsStrip({super.key});

  @override
  State<RecommendedVendorsStrip> createState() =>
      _RecommendedVendorsStripState();
}

class _RecommendedVendorsStripState extends State<RecommendedVendorsStrip>
    with AutomaticKeepAliveClientMixin, RouteAware {
  int _activeTab = 0;
  Set<String> _wishlistIds = {};

  static final routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshWishlist();
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

  @override
  void didPopNext() => _refreshWishlist();

  Future<void> _refreshWishlist() async {
    final list = await WishlistManager.getWishlist();
    if (mounted) {
      setState(() => _wishlistIds = list.map((v) => v.vendorId).toSet());
    }
  }

  Future<void> _toggleWishlist(Vendor vendor) async {
    final wv = WishlistVendor(
      vendorId: vendor.id,
      name: vendor.name,
      imageUrl: vendor.imageUrl,
      address: vendor.address,
      category: vendor.category,
      rating: vendor.rating,
    );
    await WishlistManager.toggle(wv);
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
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openVendor(BuildContext context, Vendor vendor) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            VendorItemsPage(vendorId: vendor.id, vendorName: vendor.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _tab(context, 'Recommended', 0)),
                const SizedBox(width: 4),
                Expanded(
                  child: _tab(
                    context,
                    'Favourites',
                    1,
                    icon: _activeTab == 1
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24), // Added more padding here
        Consumer(
          builder: (context, ref, _) {
            final vendorsAsync = ref.watch(vendorsStreamProvider);
            return vendorsAsync.when(
              loading: () => const RecommendedVendorsSkeleton(),
              error: (_, __) =>
                  const Center(child: Text('Error loading vendors')),
              data: (allVendors) {
                var displayed = List<Vendor>.from(allVendors);

                if (_activeTab == 1) {
                  displayed = displayed
                      .where((v) => _wishlistIds.contains(v.id))
                      .toList();
                } else {
                    // Show all vendors in Recommended
                }

                displayed.sort((a, b) {
                  if (a.isAvailable == b.isAvailable) return 0;
                  return a.isAvailable ? -1 : 1;
                });

                if (displayed.isEmpty) {
                  return Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeTab == 1
                              ? Icons.favorite_border_rounded
                              : Icons.store_outlined,
                          size: 42,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _activeTab == 1
                              ? 'No favourites yet'
                              : 'No vendors available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Doubled dimensions maintaining 2:1 ratio (240x120)
                const double cardWidth = 240.0;
                const double cardHeight = 120.0;
                const double spacing = 12.0;

                return SizedBox(
                  height: (cardHeight * 2) + spacing + 10, // Height for 2 rows + spacing + shadow
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayed.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: cardHeight / cardWidth, // 0.5 ratio
                    ),
                    itemBuilder: (ctx, i) {
                      final v = displayed[i];
                      return _VendorMiniCard(
                        vendor: v,
                        isFavourite: _wishlistIds.contains(v.id),
                        onFavouriteTap: () => _toggleWishlist(v),
                        onTap: () => _openVendor(ctx, v),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _tab(BuildContext context, String label, int index, {IconData? icon}) {
    final isActive = _activeTab == index;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? cs.surfaceContainerHighest : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.2) 
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? (index == 1 ? Colors.red : cs.onSurface) : Colors.grey,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? cs.onSurface : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorMiniCard extends StatelessWidget {
  final Vendor vendor;
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
    final cs = Theme.of(context).colorScheme;
    final placeholder = cs.surfaceContainerHighest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 120,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Image section (Left)
            SizedBox(
              width: 110,
              height: 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: vendor.imageUrl.trim().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: vendor.imageUrl.trim(),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: placeholder),
                        errorWidget: (_, __, ___) => Container(
                          color: placeholder,
                          child: Icon(Icons.store, size: 30, color: cs.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        color: placeholder,
                        child: Icon(Icons.store, size: 30, color: cs.onSurfaceVariant),
                      ),
              ),
            ),
            // 2. Info section (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onFavouriteTap,
                          child: Icon(
                            isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavourite ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Info row pinned to bottom
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 1),
                              const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          '20 min',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
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
}
