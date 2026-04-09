import 'package:cloud_firestore/cloud_firestore.dart';

class CouponRedemption {
  final String id;
  final String userId;
  final String couponId;
  final int count;

  const CouponRedemption({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.count,
  });

  factory CouponRedemption.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CouponRedemption(
      id: doc.id,
      userId: d['userId'] ?? '',
      couponId: d['couponId'] ?? '',
      count: (d['count'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'couponId': couponId,
    'count': count,
  };
}
