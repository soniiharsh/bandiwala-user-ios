import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings_screen.dart';
import 'bottom_navigation.dart';
import 'top_bar.dart';
import 'vendor_items_page.dart';
import 'cart_screen.dart';   // must contain class CartScreen
import 'help_screen.dart';  // must contain class HelpScreen

class HomePage extends StatefulWidget {
  final String? phoneNumber;
  const HomePage({super.key, this.phoneNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(phoneNumber: widget.phoneNumber),
      const CartScreen(),
      const HelpScreen(),
    ];

    return Scaffold(
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
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String? phoneNumber;
  const _HomeTab({this.phoneNumber});

  // You can delete this if unused
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          BandiwalaTopBar(phoneNumber: phoneNumber),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                SizedBox(height: 8),
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

class _VendorCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isAvailable,
      child: Stack(
        children: [
          GestureDetector(
            onTap: isAvailable
                ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VendorItemsPage(
                    vendorId: vendorId,
                    vendorName: name,
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
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
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
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.grey.shade600,
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
                                    rating.toStringAsFixed(1),
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
                                address,
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
                          category,
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
          if (!isAvailable)
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
