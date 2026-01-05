import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'top_bar.dart';
import 'bottom_navigation.dart';
import 'cart_screen.dart';
import 'help_screen.dart';
import 'cart_store.dart'; // cartStore, CartStore

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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _VendorItemsTab(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
      ),
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

class _VendorItemsTab extends StatelessWidget {
  final String vendorId;
  final String vendorName;

  const _VendorItemsTab({
    required this.vendorId,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const BandiwalaTopBar(phoneNumber: null),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                vendorName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .doc(vendorId)
                  .collection('items')
                  .orderBy('createdAt', descending: false)
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
                    child: Text('No items available for this vendor'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: GridView.builder(
                    itemCount: docs.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // we control height inside card, keep ratio close to phone
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data =
                      doc.data() as Map<String, dynamic>;

                      final String itemId = doc.id;
                      final String name = data['name'] ?? 'Item';
                      final String imageUrl = data['imageUrl'] ?? '';
                      final String category = data['category'] ?? '';
                      final String description =
                          data['description'] ?? '';
                      final bool isAvailable =
                          data['isAvailable'] ?? true;
                      final bool isVeg = data['isVeg'] ?? true;
                      final num price = data['price'] ?? 0;
                      final double rating =
                      (data['rating'] ?? 4.2).toDouble();
                      final int ratingCount =
                      (data['ratingCount'] ?? 0).toInt();

                      return _ItemCard(
                        vendorId: vendorId,
                        vendorName: vendorName,
                        itemId: itemId,
                        name: name,
                        imageUrl: imageUrl,
                        category: category,
                        description: description,
                        isAvailable: isAvailable,
                        isVeg: isVeg,
                        price: price.toDouble(),
                        rating: rating,
                        ratingCount: ratingCount,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final badgeColor = isVeg ? Colors.green.shade600 : Colors.red.shade600;

    return IgnorePointer(
      ignoring: !isAvailable,
      child: SizedBox(
        height: 260, // hard cap for everything inside
        child: Card(
          color: Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE – slightly shorter to free space for button
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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

              // CONTENT + BUTTON
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row (veg + category)
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: badgeColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // NAME – slightly smaller and single line
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // DESCRIPTION – very compact, at most 1 line
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 3),

                      // RATING + PRICE – compact row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                if (ratingCount > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    '($ratingCount)',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // BUTTON / COUNTER – always visible inside card
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

/// Local state widget to toggle between ADD and counter
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
  int qty = 0;

  void _addFirst() {
    cartStore.addItem(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
      itemId: widget.itemId,
      itemName: widget.itemName,
      price: widget.price,
    );
    setState(() => qty = 1);
  }

  void _change(int delta) {
    cartStore.updateQuantity(
      vendorId: widget.vendorId,
      itemId: widget.itemId,
      delta: delta,
    );
    setState(() => qty = (qty + delta).clamp(0, 99));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: const Text('UNAVAILABLE'),
        ),
      );
    }

    if (qty == 0) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _addFirst,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(
              color: Colors.green.shade600,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'ADD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.green.shade600,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _change(-1),
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => _change(1),
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
        ],
      ),
    );
  }
}
