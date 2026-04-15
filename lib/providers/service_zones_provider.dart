import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_zone.dart';
import '../core/db_collections.dart';

final serviceZonesProvider = FutureProvider<List<ServiceZone>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(DbCollections.serviceZones)
      .get();
  return snap.docs.map(ServiceZone.fromDoc).toList();
});
