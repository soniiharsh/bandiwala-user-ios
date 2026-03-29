import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

@freezed
class Coupon with _$Coupon {
  const Coupon._();

  const factory Coupon({
    required String id,
    required String couponCode,
    required String couponName,
    required String couponType, // "discount" | "free_delivery" | "flat_off"
    required String description,
    required double minAmount,
    required int maxDiscountableAmount,
    required double discount,
    required int maxUsage,
    required int currentUsage,
    required bool isActive,
    required DateTime createdAt,

    /// "" = global coupon (applies to entire order)
    /// "<vendorId>" = vendor-specific (applies only to that vendor's items)
    @Default('') String vendorId,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);

  factory Coupon.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      couponCode: d['couponCode'] ?? '',
      couponName: d['couponName'] ?? '',
      couponType: d['couponType'] ?? 'discount',
      description: d['description'] ?? '',
      minAmount: (d['minAmount'] as num? ?? 0).toDouble(),
      maxDiscountableAmount: (d['maxDiscountableAmount'] as num? ?? 0).toInt(),
      discount:
          (d['discount'] ?? d['discountValue'] ?? d['discountAmount'] ?? 0)
              .toDouble(),
      maxUsage: (d['maxUsage'] as num? ?? 0).toInt(),
      currentUsage: (d['currentUsage'] as num? ?? 0).toInt(),
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vendorId: d['vendorId'] ?? '',
    );
  }

  bool get isGlobal => vendorId.isEmpty;

  bool get isUsageLimitReached => maxUsage > 0 && currentUsage >= maxUsage;

  bool get isValid => isActive && !isUsageLimitReached;

  Map<String, dynamic> toMap() => {
    'id': id,
    'couponCode': couponCode,
    'couponName': couponName,
    'couponType': couponType,
    'description': description,
    'minAmount': minAmount,
    'maxDiscountableAmount': maxDiscountableAmount,
    'discount': discount,
    'maxUsage': maxUsage,
    'currentUsage': currentUsage,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'vendorId': vendorId,
  };
}
