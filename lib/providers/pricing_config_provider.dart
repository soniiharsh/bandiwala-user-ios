import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pricing config — fetched once and cached
final pricingConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('pricing_config')
      .doc('defaults')
      .get();
  return (doc.exists ? doc.data() : null) ?? {};
});
