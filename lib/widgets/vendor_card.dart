import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/vendor_items_page.dart';
import '../core/theme/theme.dart';

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

class VendorCard extends StatefulWidget {
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
  State<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  static const Color _yellow = AppColors.primary;
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    WishlistManager.isInWishlist(widget.vendorId).then((v) {
      if (mounted) setState(() => _inWishlist = v);
    });
  }

  Future<void> _toggleWishlist() async {
    await WishlistManager.toggle(
      WishlistVendor(
        vendorId: widget.vendorId,
        name: widget.name,
        imageUrl: widget.imageUrl,
        address: widget.address,
        category: widget.category,
        rating: widget.rating,
      ),
    );
    final now = await WishlistManager.isInWishlist(widget.vendorId);
    if (!mounted) return;
    setState(() => _inWishlist = now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          now
              ? '${widget.name} added to wishlist'
              : '${widget.name} removed from wishlist',
        ),
        backgroundColor: now ? Colors.green : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isAvailable,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.isAvailable
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorItemsPage(
                        vendorId: widget.vendorId,
                        vendorName: widget.name,
                      ),
                    ),
                  )
                : null,
            child: Card(
              elevation: 1.5,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: widget.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: 400,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _yellow,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.store)),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.store)),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleWishlist,
                              child: Icon(
                                _inWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: _inWishlist
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.address,
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
                        if (widget.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        if (widget.matchingItems != null &&
                            widget.matchingItems!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.matchingItems!
                                .take(3)
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _yellow.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _yellow.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${item['name']} · ₹${item['price']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isAvailable)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '😴 VENDOR OFFLINE',
                      style: TextStyle(
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
    );
  }
}
