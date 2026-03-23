import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/user_provider.dart';

/// Places an order in Firestore and returns the generated document ID.
/// Pass an [AppOrder] with [id] set to '' — the real ID comes from Firestore.
Future<String> placeOrder(AppOrder order) async {
  final data = {
    'userId': order.userId,
    'customerPhone': order.customerPhone,
    'deliveryAddress': order.deliveryAddress.toMap(),
    'itemsByVendor': order.itemsByVendor.map(
      (vendorId, vo) => MapEntry(vendorId, {
        'vendorName': vo.vendorName,
        'items': vo.items.map((itemId, item) => MapEntry(itemId, item.toMap())),
        'status': vo.status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      }),
    ),
    'vendorIds': order.vendorIds,
    'paymentMethod': order.paymentMethod,
    'paymentId': order.paymentId,
    'deliveryFee': order.deliveryFee,
    'platformFee': order.platformFee,
    'foodTax': order.foodTax,
    'deliveryTax': order.deliveryTax,
    'platformTax': order.platformTax,
    'couponApplied': order.couponApplied,
    'couponCode': order.couponCode,
    'couponType': order.couponType,
    'couponDiscount': order.couponDiscount,
    'couponMaxDiscountableAmount': order.couponMaxDiscountableAmount,
    'grandTotal': order.grandTotal,
    'status': order.status,
    'createdAt': FieldValue.serverTimestamp(),
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  };

  final ref = await FirebaseFirestore.instance.collection('orders').add(data);
  return ref.id;
}

// Stream of current user's orders — sorted client-side to avoid composite index
final userOrdersProvider = StreamProvider<List<AppOrder>>((ref) {
  final authAsync = ref.watch(userProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        final orders = snap.docs.map(AppOrder.fromDoc).toList();
        orders.sort((a, b) {
          final at = a.createdAt;
          final bt = b.createdAt;
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });
        return orders;
      });
});

// Active order (not completed/cancelled) for the status bar
final activeOrderProvider = Provider<AppOrder?>((ref) {
  final orders = ref.watch(userOrdersProvider).valueOrNull ?? [];
  try {
    return orders.firstWhere(
      (o) => o.status != 'completed' && o.status != 'cancelled',
    );
  } catch (_) {
    return null;
  }
});
