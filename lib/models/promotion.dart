import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String imageUrl;
  final int order;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.imageUrl,
    required this.order,
    required this.isActive,
  });

  factory Promotion.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      imageUrl: d['imageUrl'] ?? '',
      order: (d['order'] as num? ?? 0).toInt(),
      isActive: d['isActive'] ?? true,
    );
  }
}
