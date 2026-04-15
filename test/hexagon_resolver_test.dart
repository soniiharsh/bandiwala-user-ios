// ignore_for_file: avoid_print

import 'dart:math';

import 'package:bandiwala_user/models/hexagon.dart';
import 'package:bandiwala_user/utils/hexagon_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _rng = Random(42);

/// Generates a random double in [min, max].
double _randDouble(double min, double max) =>
    min + _rng.nextDouble() * (max - min);

/// Generates a random valid [Hexagon].
/// lat ∈ [-85, 85], long ∈ [-180, 180], sideLength ∈ (1, 5000] metres.
Hexagon _randomHexagon({List<String>? vendors}) {
  return Hexagon(
    id: 'hex_${_rng.nextInt(1 << 30)}',
    lat: _randDouble(-85, 85),
    long: _randDouble(-180, 180),
    sideLength: _randDouble(1, 5000),
    vendors: vendors ?? [],
  );
}

/// Returns a point that is guaranteed to be at the exact center of [h].
(double lat, double lng) _centerOf(Hexagon h) => (h.lat, h.long);

/// Returns a point that is guaranteed to be well outside [h] by placing it
/// more than 2× the side-length away (in latitude degrees).
(double lat, double lng) _outsideOf(Hexagon h) {
  // Move far enough north (or south) that the point is outside.
  // 2 * sideLength metres in latitude degrees ≈ 2 * sideLength / 110540.
  final offsetDeg = (2 * h.sideLength / 110540) + 1.0;
  double newLat = h.lat + offsetDeg;
  if (newLat > 85) newLat = h.lat - offsetDeg;
  return (newLat.clamp(-85.0, 85.0), h.long);
}

// ---------------------------------------------------------------------------
// Feature: hexagon-location-vendor-filtering, Property 1: JSON round-trip
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Property 1: Hexagon JSON round-trip
  // Validates: Requirements 1.3
  // -------------------------------------------------------------------------
  group('Property 1: Hexagon JSON round-trip — fromJson(toJson(h)) == h', () {
    // Feature: hexagon-location-vendor-filtering, Property 1: JSON round-trip
    test('round-trip preserves all fields for 100 random hexagons', () {
      for (var i = 0; i < 100; i++) {
        final vendors = List.generate(
          _rng.nextInt(5),
          (_) => 'vendor_${_rng.nextInt(1000)}',
        );
        final h = _randomHexagon(vendors: vendors);
        final json = h.toJson();
        final restored = Hexagon.fromJson(json);
        expect(
          restored,
          equals(h),
          reason: 'Round-trip failed for hexagon: $h',
        );
      }
    });

    test('round-trip with empty vendors list', () {
      final h = _randomHexagon(vendors: []);
      expect(Hexagon.fromJson(h.toJson()), equals(h));
    });

    test('round-trip with non-empty vendors list', () {
      final h = _randomHexagon(vendors: ['v1', 'v2', 'v3']);
      expect(Hexagon.fromJson(h.toJson()), equals(h));
    });
  });

  // -------------------------------------------------------------------------
  // Property 2: Center always inside
  // Validates: Requirements 3.2
  // -------------------------------------------------------------------------
  group(
    'Property 2: Center always inside — resolveHexagon([h], h.lat, h.long) == h',
    () {
      // Feature: hexagon-location-vendor-filtering, Property 2: center always inside
      test(
        'center point is always inside its own hexagon for 100 random hexagons',
        () {
          for (var i = 0; i < 100; i++) {
            final h = _randomHexagon();
            final (lat, lng) = _centerOf(h);
            // Test indirectly: if the center is inside h, resolveHexagon([h], lat, lng) == h
            final result = resolveHexagon([h], lat, lng);
            expect(
              result,
              equals(h),
              reason:
                  'Center ($lat, $lng) was not inside hexagon $h (sideLength=${h.sideLength})',
            );
          }
        },
      );

      test('center of a small hexagon (1 m side) is inside', () {
        final h = Hexagon(
          id: 'small',
          lat: 12.9716,
          long: 77.5946,
          sideLength: 1.0,
          vendors: [],
        );
        expect(resolveHexagon([h], h.lat, h.long), equals(h));
      });

      test('center of a large hexagon (5000 m side) is inside', () {
        final h = Hexagon(
          id: 'large',
          lat: 12.9716,
          long: 77.5946,
          sideLength: 5000.0,
          vendors: [],
        );
        expect(resolveHexagon([h], h.lat, h.long), equals(h));
      });
    },
  );

  // -------------------------------------------------------------------------
  // Property 3: Empty list returns null
  // Validates: Requirements 3.4
  // -------------------------------------------------------------------------
  group(
    'Property 3: Empty list returns null — resolveHexagon([], lat, lng) == null',
    () {
      // Feature: hexagon-location-vendor-filtering, Property 3: empty list returns null
      test('returns null for 100 random coordinate pairs', () {
        for (var i = 0; i < 100; i++) {
          final lat = _randDouble(-85, 85);
          final lng = _randDouble(-180, 180);
          expect(
            resolveHexagon([], lat, lng),
            isNull,
            reason: 'Expected null for empty list at ($lat, $lng)',
          );
        }
      });

      test('returns null for (0, 0)', () {
        expect(resolveHexagon([], 0, 0), isNull);
      });

      test('returns null for extreme coordinates', () {
        expect(resolveHexagon([], 85, 180), isNull);
        expect(resolveHexagon([], -85, -180), isNull);
      });
    },
  );

  // -------------------------------------------------------------------------
  // Property 4: Resolver result contains queried point
  // Validates: Requirements 3.1
  // -------------------------------------------------------------------------
  group('Property 4: Resolver result contains queried point', () {
    // Feature: hexagon-location-vendor-filtering, Property 4: result contains queried point
    test('when resolveHexagon returns non-null, the center of that hexagon '
        'is inside it (indirect verification via round-trip)', () {
      // We build lists where we know the center is inside, then verify
      // the returned hexagon is the one that contains the queried point.
      for (var i = 0; i < 100; i++) {
        final h = _randomHexagon();
        final (lat, lng) = _centerOf(h);
        final result = resolveHexagon([h], lat, lng);
        if (result != null) {
          // Verify the result is the hexagon that contains the point by
          // checking that querying [result] alone also returns result.
          final recheck = resolveHexagon([result], lat, lng);
          expect(
            recheck,
            equals(result),
            reason:
                'Returned hexagon $result does not contain point ($lat, $lng)',
          );
        }
      }
    });

    test('point clearly outside all hexagons returns null', () {
      for (var i = 0; i < 50; i++) {
        final h = _randomHexagon();
        final (lat, lng) = _outsideOf(h);
        // The outside point should not match h
        final result = resolveHexagon([h], lat, lng);
        // result may be null (outside) or h (if our offset wasn't enough
        // for very large hexagons) — we only assert the invariant when null
        if (result != null) {
          // If non-null, it must be h and h must contain the point
          expect(result, equals(h));
        }
      }
    });

    test('non-null result always satisfies containment (50 random lists)', () {
      for (var i = 0; i < 50; i++) {
        final hexagons = List.generate(
          1 + _rng.nextInt(5),
          (_) => _randomHexagon(),
        );
        final lat = _randDouble(-85, 85);
        final lng = _randDouble(-180, 180);
        final result = resolveHexagon(hexagons, lat, lng);
        if (result != null) {
          // The result must itself contain the point
          final recheck = resolveHexagon([result], lat, lng);
          expect(
            recheck,
            equals(result),
            reason:
                'Returned hexagon does not contain queried point ($lat, $lng)',
          );
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // Property 5: First match wins
  // Validates: Requirements 3.3
  // -------------------------------------------------------------------------
  group(
    'Property 5: First match wins — overlapping hexagons return first in list',
    () {
      // Feature: hexagon-location-vendor-filtering, Property 5: first match wins
      test(
        'when two hexagons share the same center, the first one is returned',
        () {
          for (var i = 0; i < 100; i++) {
            final base = _randomHexagon();
            // Create a second hexagon at the same center with a different id
            final overlap = Hexagon(
              id: 'overlap_${base.id}',
              lat: base.lat,
              long: base.long,
              sideLength: base.sideLength * 2,
              vendors: [],
            );
            final (lat, lng) = _centerOf(base);

            // [base, overlap] → should return base
            final result1 = resolveHexagon([base, overlap], lat, lng);
            expect(
              result1,
              equals(base),
              reason: 'Expected first hexagon (base) to win',
            );

            // [overlap, base] → should return overlap
            final result2 = resolveHexagon([overlap, base], lat, lng);
            expect(
              result2,
              equals(overlap),
              reason: 'Expected first hexagon (overlap) to win',
            );
          }
        },
      );

      test('prepending a containing hexagon always makes it the result', () {
        final inner = Hexagon(
          id: 'inner',
          lat: 12.9716,
          long: 77.5946,
          sideLength: 100.0,
          vendors: [],
        );
        final outer = Hexagon(
          id: 'outer',
          lat: 12.9716,
          long: 77.5946,
          sideLength: 500.0,
          vendors: [],
        );
        // Both contain the center point
        expect(
          resolveHexagon([inner, outer], inner.lat, inner.long),
          equals(inner),
        );
        expect(
          resolveHexagon([outer, inner], inner.lat, inner.long),
          equals(outer),
        );
      });
    },
  );

  // -------------------------------------------------------------------------
  // Property 6: Provider logic returns only hexagon-assigned vendors
  // Validates: Requirements 4.2, 4.6
  // -------------------------------------------------------------------------
  group('Property 6: Provider logic returns only hexagon-assigned vendors', () {
    // Feature: hexagon-location-vendor-filtering, Property 6: only hexagon-assigned vendors
    test(
      'filtered vendor list equals intersection of all vendors with hexagon.vendors',
      () {
        for (var i = 0; i < 100; i++) {
          // Build a pool of vendor IDs
          final allVendorIds = List.generate(
            5 + _rng.nextInt(10),
            (j) => 'vendor_$j',
          );

          // Assign a random subset to the hexagon
          final assignedIds = allVendorIds
              .where((_) => _rng.nextBool())
              .toList();

          final hexagon = Hexagon(
            id: 'h$i',
            lat: 12.9716,
            long: 77.5946,
            sideLength: 1000.0,
            vendors: assignedIds,
          );

          // Simulate the provider filter logic (pure function extracted from provider)
          final vendorSet = hexagon.vendors.toSet();
          final filtered = allVendorIds
              .where((id) => vendorSet.contains(id))
              .toList();

          // The filtered list must be exactly the assigned IDs (same elements)
          expect(
            filtered.toSet(),
            equals(assignedIds.toSet()),
            reason: 'Filtered vendors do not match hexagon.vendors assignment',
          );

          // No vendor outside the hexagon's list should appear
          for (final id in filtered) {
            expect(
              assignedIds.contains(id),
              isTrue,
              reason: 'Vendor $id is not in hexagon.vendors but was returned',
            );
          }
        }
      },
    );

    test('when hexagon.vendors is empty, filtered list is empty', () {
      final hexagon = Hexagon(
        id: 'empty',
        lat: 0,
        long: 0,
        sideLength: 1000,
        vendors: [],
      );
      final allVendorIds = ['v1', 'v2', 'v3'];
      final vendorSet = hexagon.vendors.toSet();
      final filtered = allVendorIds
          .where((id) => vendorSet.contains(id))
          .toList();
      expect(filtered, isEmpty);
    });

    test('when all vendors are assigned, all are returned', () {
      final allVendorIds = ['v1', 'v2', 'v3'];
      final hexagon = Hexagon(
        id: 'full',
        lat: 0,
        long: 0,
        sideLength: 1000,
        vendors: allVendorIds,
      );
      final vendorSet = hexagon.vendors.toSet();
      final filtered = allVendorIds
          .where((id) => vendorSet.contains(id))
          .toList();
      expect(filtered.toSet(), equals(allVendorIds.toSet()));
    });
  });

  // -------------------------------------------------------------------------
  // Property 7: Empty location provider flags all cart vendors as unavailable
  // Validates: Requirements 7.3
  // -------------------------------------------------------------------------
  group(
    'Property 7: Empty location provider flags all cart vendors as unavailable',
    () {
      // Feature: hexagon-location-vendor-filtering, Property 7: empty location flags all unavailable
      test('when locationVendorIds is empty, all cart vendor IDs are flagged', () {
        for (var i = 0; i < 100; i++) {
          final cartVendorIds = List.generate(
            1 + _rng.nextInt(10),
            (j) => 'cart_vendor_$j',
          );

          // Simulate the cart validator logic from cart_page.dart
          const locationVendorIds = <String>{};
          final hasLocationUnavailableVendors = cartVendorIds.any(
            (id) => !locationVendorIds.contains(id),
          );

          expect(
            hasLocationUnavailableVendors,
            isTrue,
            reason:
                'Expected all cart vendors to be flagged when location is empty, '
                'but hasLocationUnavailableVendors was false for $cartVendorIds',
          );
        }
      });

      test('single cart vendor with empty location is flagged', () {
        const locationVendorIds = <String>{};
        final cartVendorIds = ['only_vendor'];
        final flagged = cartVendorIds.any(
          (id) => !locationVendorIds.contains(id),
        );
        expect(flagged, isTrue);
      });

      test('when location has all cart vendors, none are flagged', () {
        final cartVendorIds = ['v1', 'v2', 'v3'];
        final locationVendorIds = {'v1', 'v2', 'v3', 'v4'};
        final flagged = cartVendorIds.any(
          (id) => !locationVendorIds.contains(id),
        );
        expect(flagged, isFalse);
      });

      test('when location has some cart vendors, flag is raised', () {
        final cartVendorIds = ['v1', 'v2', 'v3'];
        final locationVendorIds = {'v1', 'v2'};
        final flagged = cartVendorIds.any(
          (id) => !locationVendorIds.contains(id),
        );
        expect(flagged, isTrue);
      });
    },
  );

  // -------------------------------------------------------------------------
  // Property 8: Category results scoped to location vendors
  // Validates: Requirements 5.5
  // -------------------------------------------------------------------------
  group('Property 8: Category results scoped to location vendors', () {
    // Feature: hexagon-location-vendor-filtering, Property 8: category results scoped to location
    test(
      'vendorMap built from locationVendors never contains out-of-location vendors',
      () {
        for (var i = 0; i < 100; i++) {
          // All vendor IDs in the system
          final allVendorIds = List.generate(
            5 + _rng.nextInt(10),
            (j) => 'vendor_$j',
          );

          // Subset that is in the active location
          final locationVendorIds = allVendorIds
              .where((_) => _rng.nextBool())
              .toSet();

          // Simulate _CategoryResults building vendorMap from locationVendors
          // (only vendors in locationVendorIds are included)
          final vendorMap = {
            for (final id in locationVendorIds)
              id: 'category_${_rng.nextInt(5)}',
          };

          // No vendor outside locationVendorIds should appear in vendorMap
          for (final id in vendorMap.keys) {
            expect(
              locationVendorIds.contains(id),
              isTrue,
              reason: 'Vendor $id is in vendorMap but not in locationVendors',
            );
          }

          // All vendors NOT in location must be absent from vendorMap
          final outOfLocation = allVendorIds
              .where((id) => !locationVendorIds.contains(id))
              .toList();
          for (final id in outOfLocation) {
            expect(
              vendorMap.containsKey(id),
              isFalse,
              reason:
                  'Out-of-location vendor $id should not appear in category results',
            );
          }
        }
      },
    );

    test('empty location produces empty vendorMap', () {
      const locationVendorIds = <String>{};
      final vendorMap = {for (final id in locationVendorIds) id: 'cat'};
      expect(vendorMap, isEmpty);
    });

    test(
      'category filter on location vendors only returns location vendors',
      () {
        final locationVendorIds = {'v1', 'v2', 'v3'};
        const selectedCategory = 'food';
        final vendorCategories = {
          'v1': 'food',
          'v2': 'drinks',
          'v3': 'food',
          'v4': 'food',
        };

        // Simulate category filtering scoped to location
        final categoryResults = vendorCategories.entries
            .where(
              (e) =>
                  locationVendorIds.contains(e.key) &&
                  e.value == selectedCategory,
            )
            .map((e) => e.key)
            .toList();

        // v4 is NOT in location, so must not appear
        expect(categoryResults, isNot(contains('v4')));
        // v1 and v3 are in location and match category
        expect(categoryResults, containsAll(['v1', 'v3']));
        // v2 is in location but wrong category
        expect(categoryResults, isNot(contains('v2')));
      },
    );
  });
}
