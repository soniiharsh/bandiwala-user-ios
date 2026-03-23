// active_address_provider.dart
//
// Single source of truth for the user's active delivery address.
//
// - Reads the default index from SharedPreferences on init
// - Derives the SavedAddress from authProvider.savedAddresses[index]
// - Exposes setAddress(SavedAddress) which updates both state + SharedPrefs
// - Returns null when the user has no saved addresses

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'user_provider.dart';

const _kDefaultIndexKey = 'default_address_index';

class ActiveAddressNotifier extends Notifier<SavedAddress?> {
  @override
  SavedAddress? build() {
    // Re-derive whenever userProvider changes (new login, address list updated)
    final appUser = ref.watch(userProvider).valueOrNull;
    if (appUser == null || appUser.savedAddresses.isEmpty) return null;

    // We keep the last-chosen index in _index (persisted to SharedPrefs).
    // On first build _index is 0; it gets updated by setAddress().
    final idx = _index < appUser.savedAddresses.length ? _index : 0;
    return appUser.savedAddresses[idx];
  }

  // ── Internal index — kept in sync with SharedPreferences ─────────────────

  int _index = 0;

  /// Call once at app start (e.g. in main or splash) to hydrate from prefs.
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _index = prefs.getInt(_kDefaultIndexKey) ?? 0;
      // Trigger a rebuild so the derived address reflects the loaded index
      ref.invalidateSelf();
    } catch (_) {}
  }

  /// Select a new active address. Persists the index to SharedPreferences.
  Future<void> setAddress(SavedAddress loc) async {
    final appUser = ref.read(userProvider).valueOrNull;
    if (appUser == null) return;

    final idx = appUser.savedAddresses.indexWhere(
      (a) =>
          (a.latitude - loc.latitude).abs() < 0.0005 &&
          (a.longitude - loc.longitude).abs() < 0.0005,
    );

    if (idx >= 0) {
      _index = idx;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kDefaultIndexKey, idx);
      } catch (_) {}
    }

    // Always update state to the chosen location (even if not in saved list)
    state = loc;
  }
}

final activeAddressProvider =
    NotifierProvider<ActiveAddressNotifier, SavedAddress?>(
      ActiveAddressNotifier.new,
    );
