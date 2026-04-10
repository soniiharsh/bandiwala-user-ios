import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon.dart';
import '../models/coupon_redemption.dart';
import '../core/db_collections.dart';
import 'user_provider.dart';

// Global coupons — vendorId == "" — fetched once and cached
// Secret coupons are excluded; they can only be found via direct code search.
final activeCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.coupons)
      .where('vendorId', isEqualTo: '')
      .where('isActive', isEqualTo: true)
      .where('secret', isEqualTo: false)
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

/// Fetches a single coupon by exact coupon code — includes secret coupons.
/// Returns null if not found or not valid.
Future<Coupon?> fetchCouponByCode(String code) async {
  if (code.trim().isEmpty) return null;
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.coupons)
      .where('couponCode', isEqualTo: code.trim())
      .where('isActive', isEqualTo: true)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  final coupon = Coupon.fromDoc(snap.docs.first);
  return coupon.isValid ? coupon : null;
}

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
