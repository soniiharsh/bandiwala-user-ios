import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String vendorId,
    required String name,
    @Default('') String description,
    required double price,
    @Default('') String imageUrl,
    @Default('') String category,
    @Default([]) List<String> tags,
    @Default(true) bool isVeg,
    @Default(true) bool isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

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
