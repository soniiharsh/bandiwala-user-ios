import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon.dart';

// All active coupons — one-time fetch, not reactive
final activeCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('coupons')
      .where('isActive', isEqualTo: true)
      .get();
  return snap.docs.map(Coupon.fromDoc).where((c) => c.isValid).toList();
});

Future<void> incrementCouponUsage(String couponId) async {
  await FirebaseFirestore.instance.collection('coupons').doc(couponId).update({
    'currentUsage': FieldValue.increment(1),
  });
}
