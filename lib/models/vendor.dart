import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor.freezed.dart';
part 'vendor.g.dart';

@freezed
class Vendor with _$Vendor {
  const factory Vendor({
    required String id,
    required String name,
    required String phone,
    String? fcmToken,
    @Default('') String imageUrl,
    @Default('') String address,
    @Default('') String category,
    @Default(false) bool isAvailable,
    @Default(false) bool isPickupAvailable,
    @Default(4.2) double rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Vendor;

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);

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
      isPickupAvailable: d['isPickupAvailable'] ?? false,
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
        isPickupAvailable: d['isPickupAvailable'] ?? false,
        rating: (d['rating'] ?? 4.2).toDouble(),
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      );
}
