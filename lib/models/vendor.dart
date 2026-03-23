import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String name;
  final String phone;
  final String? fcmToken;
  final String imageUrl;
  final String address;
  final String category;
  final bool isAvailable;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vendor({
    required this.id,
    required this.name,
    required this.phone,
    this.fcmToken,
    this.imageUrl = '',
    this.address = '',
    this.category = '',
    this.isAvailable = false,
    this.rating = 4.2,
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      fcmToken: d['FCMToken'],
      imageUrl: d['imageUrl'] ?? '',
      address: d['address'] ?? '',
      category: d['category'] ?? '',
      isAvailable: d['isAvailable'] ?? false,
      rating: (d['rating'] ?? 4.2).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Vendor.fromMap(String id, Map<String, dynamic> d) => Vendor(
    id: id,
    name: d['name'] ?? '',
    phone: d['phone'] ?? '',
    fcmToken: d['FCMToken'],
    imageUrl: d['imageUrl'] ?? '',
    address: d['address'] ?? '',
    category: d['category'] ?? '',
    isAvailable: d['isAvailable'] ?? false,
    rating: (d['rating'] ?? 4.2).toDouble(),
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
  );
}
