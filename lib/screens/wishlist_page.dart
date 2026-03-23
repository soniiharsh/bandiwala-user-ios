// wishlist_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'vendor_items_page.dart';
import '../widgets/vendor_card.dart'; // WishlistManager + WishlistVendor

const _kBandiwalaYellow = Color(0xFFFFC107);
const _kWhite = Color(0xFFFFFFFF);
const _kBorderGrey = Color(0xFFE5E7EB);
const _kLightGrey = Color(0xFFF9FAFB);

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> with RouteAware {
  List<WishlistVendor> _wishlist = [];
  bool _isLoading = true;

  // Same observer instance used by RecommendedVendorsStrip in promotional.dart
  static final _routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) _routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Refresh whenever user navigates back to this page
  @override
  void didPopNext() => _loadWishlist();

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final wishlist = await WishlistManager.getWishlist();
      if (mounted) {
        setState(() {
          _wishlist = wishlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(WishlistVendor vendor) async {
    await WishlistManager.removeFromWishlist(vendor.vendorId);
    await _loadWishlist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vendor.name} removed from wishlist'),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    if (_wishlist.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Wishlist'),
        content: const Text('Remove all vendors from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final v in List.of(_wishlist)) {
        await WishlistManager.removeFromWishlist(v.vendorId);
      }
      await _loadWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kLightGrey,
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _kWhite,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: _kBorderGrey),
        ),
        actions: [
          if (_wishlist.isNotEmpty)
            TextButton(
              onPressed: _confirmClearAll,
              child: const Text(
                'Clear all',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _kBandiwalaYellow,
                strokeWidth: 3,
              ),
            )
          : _wishlist.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _kBandiwalaYellow,
              onRefresh: _loadWishlist,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _wishlist.length,
                itemBuilder: (context, index) {
                  final vendor = _wishlist[index];
                  return _WishlistVendorCard(
                    vendor: vendor,
                    onRemove: () => _removeFromWishlist(vendor),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _kBandiwalaYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 80,
              color: _kBandiwalaYellow,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Favourites Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the ♥ on any vendor card\nto save it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _WishlistVendorCard ──────────────────────────────────────────────────────

class _WishlistVendorCard extends StatelessWidget {
  final WishlistVendor vendor;
  final VoidCallback onRemove;

  const _WishlistVendorCard({required this.vendor, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorItemsPage(
              vendorId: vendor.vendorId,
              vendorName: vendor.name,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Vendor Image ────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: vendor.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vendor.imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 180,
                          memCacheHeight: 180,
                          maxWidthDiskCache: 180,
                          maxHeightDiskCache: 180,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kBandiwalaYellow,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store, size: 32),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.store, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Vendor Details ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Rating chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
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
                              const SizedBox(width: 3),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (vendor.category.isNotEmpty)
                          Expanded(
                            child: Text(
                              vendor.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (vendor.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendor.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Remove (filled heart = in wishlist) ─────────────────
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite_rounded),
                color: Colors.red,
                iconSize: 24,
                tooltip: 'Remove from wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
