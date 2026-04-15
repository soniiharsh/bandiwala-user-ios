import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor.dart';
import '../utils/hexagon_resolver.dart';
import 'active_address_provider.dart';
import 'hexagon_provider.dart';
import 'vendors_provider.dart';

/// Derived provider that combines the active delivery address with hexagon
/// data to produce a filtered list of [Vendor] objects.
///
/// - Returns `AsyncData([])` when no address is selected.
/// - Propagates `AsyncLoading` / `AsyncError` from upstream providers.
/// - Returns `AsyncData([])` when no hexagon contains the active address.
/// - Otherwise returns only vendors whose IDs appear in the resolved hexagon.
final vendorsInLocationProvider = Provider<AsyncValue<List<Vendor>>>((ref) {
  final hexagonsAsync = ref.watch(hexagonProvider);
  final vendorsAsync = ref.watch(vendorsStreamProvider);
  final address = ref.watch(activeAddressProvider);

  if (address == null) return const AsyncData([]);

  return hexagonsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (hexagons) {
      return vendorsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (vendors) {
          final hexagon = resolveHexagon(
            hexagons,
            address.latitude,
            address.longitude,
          );
          if (hexagon == null) return const AsyncData([]);
          final vendorSet = hexagon.vendors.toSet();
          return AsyncData(
            vendors.where((v) => vendorSet.contains(v.id)).toList(),
          );
        },
      );
    },
  );
});
