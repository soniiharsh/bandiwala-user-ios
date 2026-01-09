// ============ home_page.dart ============
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'settings_screen.dart';
import 'bottom_navigation.dart';
import 'top_bar.dart';
import 'vendor_items_page.dart';
import 'cart_screen.dart';
import 'help_screen.dart';
import 'promotional.dart';

class HomePage extends StatefulWidget {
  final String? phoneNumber;
  const HomePage({super.key, this.phoneNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // ✅ Handle Android back button
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on home tab, go to home tab
      setState(() => _currentIndex = 0);
      return false; // Don't exit app
    }
    return true; // Exit app if already on home tab
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(phoneNumber: widget.phoneNumber),
      CartScreen(
        onBackToHome: () {
          setState(() => _currentIndex = 0);
        },
      ),
      const HelpScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0, // Only allow exit if on home tab
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentIndex != 0) {
          // Switch to home tab instead of exiting
          setState(() => _currentIndex = 0);
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

class _HomeTab extends StatelessWidget {
  final String? phoneNumber;

  const _HomeTab({this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          BandiwalaTopBar(phoneNumber: phoneNumber),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                SizedBox(height: 12),
                PromotionalBanner(),
                SizedBox(height: 16),
                Text(
                  'Vendors near you',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12),
                _VendorsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorsList extends StatelessWidget {
  const _VendorsList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No vendors available right now'),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String vendorId = data['id'] ?? doc.id;
            final String name = data['name'] ?? 'Vendor';
            final String imageUrl = data['imageUrl'] ?? '';
            final String address = data['address'] ?? '';
            final String category = data['category'] ?? '';
            final bool isAvailable = data['isAvailable'] ?? true;
            final double rating = (data['rating'] ?? 4.2).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VendorCard(
                vendorId: vendorId,
                name: name,
                imageUrl: imageUrl,
                address: address,
                category: category,
                rating: rating,
                isAvailable: isAvailable,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class WishlistVendor {
  final String vendorId;
  final String name;
  final String imageUrl;
  final String address;
  final String category;
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

  factory WishlistVendor.fromJson(Map<String, dynamic> json) => WishlistVendor(
    vendorId: json['vendorId'],
    name: json['name'],
    imageUrl: json['imageUrl'],
    address: json['address'],
    category: json['category'],
    rating: json['rating'].toDouble(),
  );
}

class WishlistManager {
  static const String _key = 'wishlist_vendors';

  static Future<List<WishlistVendor>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList(_key) ?? [];
    return wishlistJson
        .map((json) => WishlistVendor.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<bool> isInWishlist(String vendorId) async {
    final wishlist = await getWishlist();
    return wishlist.any((v) => v.vendorId == vendorId);
  }

  static Future<void> addToWishlist(WishlistVendor vendor) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = await getWishlist();

    if (wishlist.any((v) => v.vendorId == vendor.vendorId)) {
      return;
    }

    wishlist.insert(0, vendor);
    final wishlistJson = wishlist.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_key, wishlistJson);
  }

  static Future<void> removeFromWishlist(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = await getWishlist();
    wishlist.removeWhere((v) => v.vendorId == vendorId);
    final wishlistJson = wishlist.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_key, wishlistJson);
  }

  static Future<void> toggleWishlist(WishlistVendor vendor) async {
    final isInList = await isInWishlist(vendor.vendorId);
    if (isInList) {
      await removeFromWishlist(vendor.vendorId);
    } else {
      await addToWishlist(vendor);
    }
  }
}

class _VendorCard extends StatefulWidget {
  final String vendorId;
  final String name;
  final String imageUrl;
  final String address;
  final String category;
  final double rating;
  final bool isAvailable;

  const _VendorCard({
    required this.vendorId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.category,
    required this.rating,
    required this.isAvailable,
  });

  @override
  State<_VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<_VendorCard> {
  bool _isInWishlist = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final isInList = await WishlistManager.isInWishlist(widget.vendorId);
    if (mounted) {
      setState(() => _isInWishlist = isInList);
    }
  }

  Future<void> _toggleWishlist() async {
    setState(() => _isLoading = true);

    final vendor = WishlistVendor(
      vendorId: widget.vendorId,
      name: widget.name,
      imageUrl: widget.imageUrl,
      address: widget.address,
      category: widget.category,
      rating: widget.rating,
    );

    await WishlistManager.toggleWishlist(vendor);

    final isInList = await WishlistManager.isInWishlist(widget.vendorId);

    if (mounted) {
      setState(() {
        _isInWishlist = isInList;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInList
                ? '${widget.name} added to wishlist'
                : '${widget.name} removed from wishlist',
          ),
          backgroundColor: isInList ? Colors.green : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isAvailable,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.isAvailable
                ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VendorItemsPage(
                    vendorId: widget.vendorId,
                    vendorName: widget.name,
                  ),
                ),
              );
            }
                : null,
            child: Card(
              elevation: 1.5,
              color: Colors.white.withOpacity(0.94),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.store),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.store),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _isLoading ? null : _toggleWishlist,
                              child: _isLoading
                                  ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade600,
                                ),
                              )
                                  : Icon(
                                _isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: _isInWishlist
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
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                child: const Text(
                  'Currently Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
