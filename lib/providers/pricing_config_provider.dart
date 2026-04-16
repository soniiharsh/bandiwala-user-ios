import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/db_collections.dart';

// Pricing config — listens for real-time updates
final pricingConfigProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection(DbCollections.pricingConfig)
      .doc('defaults')
      .snapshots()
      .map((doc) => (doc.exists ? doc.data() : null) ?? {});
});
