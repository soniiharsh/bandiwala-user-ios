import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';

final promotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final snap = await FirebaseFirestore.instance.collection('promotions').get();
  final docs = snap.docs
      .where((d) => d.data()['isActive'] == true)
      .map(Promotion.fromDoc)
      .toList();
  docs.sort((a, b) => a.order.compareTo(b.order));
  return docs;
});
