import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_category.dart';
import '../core/db_collections.dart';

final foodCategoriesProvider = FutureProvider<List<FoodCategory>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.foodCategories)
      .where('isActive', isEqualTo: true)
      .get(const GetOptions(source: Source.serverAndCache));

  final categories = snap.docs.map(FoodCategory.fromDoc).toList();
  categories.sort((a, b) => a.order.compareTo(b.order));
  return categories;
});
