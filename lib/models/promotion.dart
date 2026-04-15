import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'promotion.freezed.dart';
part 'promotion.g.dart';

@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required String id,
    required String imageUrl,
    required int order,
    required bool isActive,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);

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
