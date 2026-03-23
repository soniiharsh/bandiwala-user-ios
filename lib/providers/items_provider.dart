import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';

// Single real-time stream of ALL items.
// Every other provider derives from this — no extra Firestore listeners.
final allItemsStreamProvider = StreamProvider<List<Item>>((ref) {
  return FirebaseFirestore.instance
      .collection('items')
      .snapshots()
      .map((snap) => snap.docs.map(Item.fromDoc).toList());
});

// Items for a specific vendor — filtered locally.
final vendorItemsStreamProvider =
    Provider.family<AsyncValue<List<Item>>, String>((ref, vendorId) {
      return ref.watch(allItemsStreamProvider).whenData((items) {
        final filtered = items.where((i) => i.vendorId == vendorId).toList();
        filtered.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return aTime.compareTo(bTime);
        });
        return filtered;
      });
    });

// Single item — filtered locally.
final itemStreamProvider = Provider.family<AsyncValue<Item?>, String>((
  ref,
  itemId,
) {
  return ref
      .watch(allItemsStreamProvider)
      .whenData(
        (items) => items.cast<Item?>().firstWhere(
          (i) => i?.id == itemId,
          orElse: () => null,
        ),
      );
});

// All available items — filtered locally (used for search & category filter).
final allAvailableItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  return ref
      .watch(allItemsStreamProvider)
      .whenData((items) => items.where((i) => i.isAvailable).toList());
});

// Available items for a vendor — filtered locally (used for suggestions).
final availableItemsForVendorProvider =
    Provider.family<AsyncValue<List<Item>>, String>((ref, vendorId) {
      return ref
          .watch(allItemsStreamProvider)
          .whenData(
            (items) => items
                .where((i) => i.vendorId == vendorId && i.isAvailable)
                .take(20)
                .toList(),
          );
    });
