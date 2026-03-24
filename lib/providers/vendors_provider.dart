import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor.dart';

// Single real-time stream of all vendors.
// Everything else derives from this — no extra Firestore listeners.
final vendorsStreamProvider = StreamProvider<List<Vendor>>((ref) {
  return FirebaseFirestore.instance
      .collection('vendors1')
      .snapshots()
      .map((snap) => snap.docs.map(Vendor.fromDoc).toList());
});

// Single vendor — derived locally from the stream above.
final vendorStreamProvider = Provider.family<AsyncValue<Vendor?>, String>((
  ref,
  vendorId,
) {
  return ref
      .watch(vendorsStreamProvider)
      .whenData(
        (vendors) => vendors.cast<Vendor?>().firstWhere(
          (v) => v?.id == vendorId,
          orElse: () => null,
        ),
      );
});
