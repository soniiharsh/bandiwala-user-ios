import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';
import 'cart_provider.dart';

// Single source of truth: AppUser?
//
// null  -> not signed in
// value -> Firebase Auth valid + Firestore user doc streamed live
//
// Also owns all Firestore writes for the user doc (including FCM token).

class UserNotifier extends AsyncNotifier<AppUser?> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  @override
  Future<AppUser?> build() async {
    _authSub?.cancel();
    _userDocSub?.cancel();

    final completer = Completer<AppUser?>();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        _userDocSub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        } else {
          state = const AsyncData(null);
        }
        return;
      }

      _userDocSub?.cancel();
      _userDocSub = FirebaseFirestore.instance
          .collection('users1')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen((doc) {
            final appUser = doc.exists ? AppUser.fromDoc(doc) : null;
            if (!completer.isCompleted) {
              completer.complete(appUser);
            } else {
              state = AsyncData(appUser);
            }
          });
    });

    ref.onDispose(() {
      _authSub?.cancel();
      _userDocSub?.cancel();
    });

    return completer.future;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await deleteFcmToken(uid);
    await ref.read(cartProvider.notifier).clear();
    await FirebaseAuth.instance.signOut();
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  Future<void> updateFcmToken(String uid) async {
    try {
      final token = await NotificationService().getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users1').doc(uid).update({
          'FCMToken': token,
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error updating FCM token: $e');
    }
  }

  Future<void> deleteFcmToken(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users1').doc(uid).update({
        'FCMToken': FieldValue.delete(),
      });
    } catch (e) {
      if (kDebugMode) print('Error deleting FCM token: $e');
    }
  }

  // ── User doc writes ───────────────────────────────────────────────────────

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> updateName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users1').doc(uid).set({
      'name': name,
    }, SetOptions(merge: true));
  }

  Future<void> addAddress(SavedAddress address) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users1').doc(uid).update({
      'savedAddresses': FieldValue.arrayUnion([address.toMap()]),
    });
  }

  Future<void> deleteAddress(int index) async {
    final uid = _uid;
    if (uid == null) return;
    final current = state.valueOrNull?.savedAddresses ?? [];
    final updated = [...current]..removeAt(index);
    await FirebaseFirestore.instance.collection('users1').doc(uid).update({
      'savedAddresses': updated.map((a) => a.toMap()).toList(),
    });
  }

  Future<void> updateAddress(int index, SavedAddress address) async {
    final uid = _uid;
    if (uid == null) return;
    final current = state.valueOrNull?.savedAddresses ?? [];
    final updated = [...current]..[index] = address;
    await FirebaseFirestore.instance.collection('users1').doc(uid).update({
      'savedAddresses': updated.map((a) => a.toMap()).toList(),
    });
  }

  Future<void> replaceAllAddresses(List<SavedAddress> addresses) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users1').doc(uid).update({
      'savedAddresses': addresses.map((a) => a.toMap()).toList(),
    });
  }

  Future<void> markDeleted() async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users1').doc(uid).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, AppUser?>(
  UserNotifier.new,
);
