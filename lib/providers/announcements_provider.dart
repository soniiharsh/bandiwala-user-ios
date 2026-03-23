import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// One-time fetch — announcements don't need to be reactive
final announcementsProvider = FutureProvider<List<String>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('announcements')
      .where('isActive', isEqualTo: true)
      .get();
  return snap.docs
      .map((doc) => doc.get('text') as String)
      .where((t) => t.isNotEmpty)
      .toList();
});
