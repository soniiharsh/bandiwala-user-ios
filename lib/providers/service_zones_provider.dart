import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_zone.dart';

final serviceZonesProvider = FutureProvider<List<ServiceZone>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('serviceLocations1')
      .get();
  return snap.docs.map(ServiceZone.fromDoc).toList();
});
