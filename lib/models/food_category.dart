import 'package:cloud_firestore/cloud_firestore.dart';

class FoodCategory {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int order;
  final DateTime? createdAt;

  const FoodCategory({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.isActive = true,
    this.order = 0,
    this.createdAt,
  });

  factory FoodCategory.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FoodCategory(
      id: doc.id,
      name: d['name'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      isActive: d['isActive'] ?? true,
      order: (d['order'] as num? ?? 0).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
