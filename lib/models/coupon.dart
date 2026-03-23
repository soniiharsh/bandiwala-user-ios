import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String couponCode;
  final String couponName;
  final String couponType; // "discount" | "free_delivery" | "flat_off"
  final String description;
  final double minAmount;
  final int maxDiscountableAmount;
  final double discount;
  final int maxUsage;
  final int currentUsage;
  final bool isActive;
  final DateTime createdAt;

  const Coupon({
    required this.id,
    required this.couponCode,
    required this.couponName,
    required this.couponType,
    required this.description,
    required this.minAmount,
    required this.maxDiscountableAmount,
    required this.discount,
    required this.maxUsage,
    required this.currentUsage,
    required this.isActive,
    required this.createdAt,
  });

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
    );
  }

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
  };
}
