import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon.dart';
import '../core/db_collections.dart';

// Global coupons — vendorId == "" — fetched once and cached
final activeCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.coupons)
      .where('vendorId', isEqualTo: '')
      .where('isActive', isEqualTo: true)
      .get();
  return snap.docs.map(Coupon.fromDoc).where((c) => c.isValid).toList();
});

// Vendor-specific coupons — fetched per vendorId, cached per vendor
final vendorCouponsProvider = FutureProvider.family<List<Coupon>, String>((
  ref,
  vendorId,
) async {
  if (vendorId.isEmpty) return [];
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.coupons)
      .where('vendorId', isEqualTo: vendorId)
      .where('isActive', isEqualTo: true)
      .get();
  return snap.docs.map(Coupon.fromDoc).where((c) => c.isValid).toList();
});

Future<void> incrementCouponUsage(String couponId) async {
  await FirebaseFirestore.instance
      .collection(DbCollections.coupons)
      .doc(couponId)
      .update({'currentUsage': FieldValue.increment(1)});
}
