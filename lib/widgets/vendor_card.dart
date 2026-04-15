import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/coupons_provider.dart';
import '../models/coupon.dart';
import '../screens/vendor_items_page.dart';
import '../core/navigation/app_page_route.dart';

// ─── Wishlist ─────────────────────────────────────────────────────────────────

class WishlistVendor {
  final String vendorId, name, imageUrl, address, category;
  final double rating;

  WishlistVendor({
    required this.vendorId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.category,
    required this.rating,
  });

  Map<String, dynamic> toJson() => {
    'vendorId': vendorId,
    'name': name,
    'imageUrl': imageUrl,
    'address': address,
    'category': category,
    'rating': rating,
  };

  factory WishlistVendor.fromJson(Map<String, dynamic> j) => WishlistVendor(
    vendorId: j['vendorId'],
    name: j['name'],
    imageUrl: j['imageUrl'],
    address: j['address'],
    category: j['category'],
    rating: (j['rating'] as num).toDouble(),
  );
}

class WishlistManager {
  static const _key = 'wishlist_vendors';

  static Future<List<WishlistVendor>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? [])
        .map((s) => WishlistVendor.fromJson(jsonDecode(s)))
        .toList();
  }

  static Future<bool> isInWishlist(String vendorId) async =>
      (await getWishlist()).any((v) => v.vendorId == vendorId);

  static Future<void> toggle(WishlistVendor vendor) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWishlist();
    final wasIn = list.any((v) => v.vendorId == vendor.vendorId);
    list.removeWhere((v) => v.vendorId == vendor.vendorId);
    if (!wasIn) list.insert(0, vendor);
    await prefs.setStringList(
      _key,
      list.map((v) => jsonEncode(v.toJson())).toList(),
    );
  }

  static Future<void> removeFromWishlist(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWishlist();
    list.removeWhere((v) => v.vendorId == vendorId);
    await prefs.setStringList(
      _key,
      list.map((v) => jsonEncode(v.toJson())).toList(),
    );
  }
}

// ─── VendorCard ───────────────────────────────────────────────────────────────

class VendorCard extends ConsumerStatefulWidget {
  final String vendorId, name, imageUrl, address, category;
  final double rating;
  final bool isAvailable;
  final List<Map<String, dynamic>>? matchingItems;

  const VendorCard({
    super.key,
    required this.vendorId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.category,
    required this.rating,
    required this.isAvailable,
    this.matchingItems,
  });

  @override
  ConsumerState<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends ConsumerState<VendorCard> {
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final inWish = await WishlistManager.isInWishlist(widget.vendorId);
    if (mounted) setState(() => _inWishlist = inWish);
  }

  Future<void> _toggleWishlist() async {
    final wv = WishlistVendor(
      vendorId: widget.vendorId,
      name: widget.name,
      imageUrl: widget.imageUrl,
      address: widget.address,
      category: widget.category,
      rating: widget.rating,
    );
    await WishlistManager.toggle(wv);
    await _checkWishlist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _inWishlist ? 'Added to wishlist' : 'Removed from wishlist',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = cs.surfaceContainerHighest;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => VendorItemsPage(
            vendorId: widget.vendorId,
            vendorName: widget.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: widget.imageUrl.trim().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.imageUrl.trim(),
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: placeholder),
                                errorWidget: (_, __, ___) => Container(
                                  color: placeholder,
                                  child: const Icon(Icons.store, size: 40),
                                ),
                              )
                            : Container(
                                color: placeholder,
                                child: const Icon(Icons.store, size: 40),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _toggleWishlist,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _inWishlist
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: _inWishlist ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '20-30 min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _VendorCardCouponStrip(vendorId: widget.vendorId),
                    ],
                  ),
                ),
              ],
            ),
            // ── Offline overlay ───────────────────────────────────────────
            if (!widget.isAvailable)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Vendor Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
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

// ─── Coupon strip shown on vendor cards in home page ─────────────────────────

class _VendorCardCouponStrip extends ConsumerWidget {
  final String vendorId;
  const _VendorCardCouponStrip({required this.vendorId});

  String _label(Coupon c) {
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
    return couponsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (coupons) {
        if (coupons.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = coupons[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 11,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _label(c),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
