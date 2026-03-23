import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final bool isVeg;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Item({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl = '',
    this.category = '',
    this.tags = const [],
    this.isVeg = true,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] as num? ?? 0).toDouble(),
      imageUrl: d['imageUrl'] ?? '',
      category: d['category'] ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      isVeg: d['isVeg'] ?? true,
      isAvailable: d['isAvailable'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Item.fromMap(String id, Map<String, dynamic> d) => Item(
    id: id,
    vendorId: d['vendorId'] ?? '',
    name: d['name'] ?? '',
    description: d['description'] ?? '',
    price: (d['price'] as num? ?? 0).toDouble(),
    imageUrl: d['imageUrl'] ?? '',
    category: d['category'] ?? '',
    tags: List<String>.from(d['tags'] ?? []),
    isVeg: d['isVeg'] ?? true,
    isAvailable: d['isAvailable'] ?? true,
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
  );
}
