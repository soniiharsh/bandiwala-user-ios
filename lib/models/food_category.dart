import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_category.freezed.dart';
part 'food_category.g.dart';

@freezed
class FoodCategory with _$FoodCategory {
  const factory FoodCategory({
    required String id,
    required String name,
    @Default('') String imageUrl,
    @Default(true) bool isActive,
    @Default(0) int order,
    DateTime? createdAt,
  }) = _FoodCategory;

  factory FoodCategory.fromJson(Map<String, dynamic> json) =>
      _$FoodCategoryFromJson(json);

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
