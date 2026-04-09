import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon.dart';
import '../models/coupon_redemption.dart';
import '../core/db_collections.dart';
import 'user_provider.dart';

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

/// Streams the current user's redemption counts as Map<couponId, count>.
/// Returns an empty map when not signed in.
final couponRedemptionsProvider = StreamProvider<Map<String, int>>((ref) {
  final uid = ref.watch(userProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value({});

  return FirebaseFirestore.instance
      .collection(DbCollections.couponRedemptions)
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        return {
          for (final doc in snap.docs)
            CouponRedemption.fromDoc(doc).couponId: CouponRedemption.fromDoc(
              doc,
            ).count,
        };
      });
});

/// Call this after a successful order to record the per-user redemption.
Future<void> recordCouponRedemption({
  required String userId,
  required String couponId,
}) async {
  final col = FirebaseFirestore.instance.collection(
    DbCollections.couponRedemptions,
  );

  // Find existing doc for this user+coupon
  final existing = await col
      .where('userId', isEqualTo: userId)
      .where('couponId', isEqualTo: couponId)
      .limit(1)
      .get();

  if (existing.docs.isEmpty) {
    await col.add({'userId': userId, 'couponId': couponId, 'count': 1});
  } else {
    await existing.docs.first.reference.update({
      'count': FieldValue.increment(1),
    });
  }
}
