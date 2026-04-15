import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hexagon.dart';
import '../core/db_collections.dart';

// Single real-time stream of all hexagons.
// vendorsInLocationProvider derives from this — no extra Firestore listeners.
final hexagonProvider = StreamProvider<List<Hexagon>>((ref) {
  return FirebaseFirestore.instance
      .collection(DbCollections.hexagons)
      .snapshots()
      .map((snap) => snap.docs.map(Hexagon.fromDoc).toList());
});
