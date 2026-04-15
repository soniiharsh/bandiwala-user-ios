import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/db_collections.dart';

// Pricing config — fetched once and cached
final pricingConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection(DbCollections.pricingConfig)
      .doc('defaults')
      .get();
  return (doc.exists ? doc.data() : null) ?? {};
});
