import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vendor.dart';
import '../screens/vendor_items_page.dart';
import '../providers/vendors_provider.dart';
import '../widgets/vendor_card.dart' show WishlistManager, WishlistVendor;
import 'promotional_banner.dart' show kBandiwalaYellow;

// ─── RecommendedVendorsStrip ──────────────────────────────────────────────────

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
        backgroundColor: isNowIn ? Colors.green : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openVendor(BuildContext context, Vendor vendor) {
    if (!vendor.isAvailable) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VendorItemsPage(vendorId: vendor.id, vendorName: vendor.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(
          height: 215,
          child: Consumer(
            builder: (context, ref, _) {
              final vendorsAsync = ref.watch(vendorsStreamProvider);
              return vendorsAsync.when(
                loading: _buildShimmer,
                error: (_, __) =>
                    const Center(child: Text('Error loading vendors')),
                data: (allVendors) {
                  var displayed = List<Vendor>.from(allVendors);

                  if (_activeTab == 1) {
                    displayed = displayed
                        .where((v) => _wishlistIds.contains(v.id))
                        .toList();
                  }

                  displayed.sort((a, b) {
                    if (a.isAvailable == b.isAvailable) return 0;
                    return a.isAvailable ? -1 : 1;
                  });

                  if (displayed.isEmpty) {
                    return Center(
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
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayed.length,
                    itemBuilder: (ctx, i) {
                      final v = displayed[i];
                      return _VendorMiniCard(
                        vendor: v,
                        isFavourite: _wishlistIds.contains(v.id),
                        onFavouriteTap: () => _toggleWishlist(v),
                        onTap: () => _openVendor(ctx, v),
                      );
                    },
                  );
                },
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
    return GestureDetector(
      onTap: onTap,
      child: IgnorePointer(
        ignoring: !vendor.isAvailable,
        child: Stack(
          children: [
            Container(
              width: 175,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                      // Favourite heart
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
                                  color: Colors.black.withValues(alpha: 0.15),
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
                    ],
                  ),
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
                            const Expanded(
                              child: Text(
                                '20-30 min',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
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
            if (!vendor.isAvailable)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OFFLINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
