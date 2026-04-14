import 'dart:math';

import 'package:bandiwala_user/models/hexagon.dart';

/// Returns the first [Hexagon] in [hexagons] whose boundary contains the
/// point ([lat], [lng]), or `null` if none match.
///
/// When multiple hexagons contain the same point, the first one in list order
/// is returned (deterministic, first-match-wins).
Hexagon? resolveHexagon(List<Hexagon> hexagons, double lat, double lng) {
  for (final h in hexagons) {
    if (_pointInHexagon(h, lat, lng)) return h;
  }
  return null;
}

/// Returns `true` if ([lat], [lng]) falls inside the flat-top regular hexagon
/// centered at ([h.lat], [h.long]) with side length [h.sideLength] meters.
///
/// Coordinate-to-meters conversion (consistent with haversineDistance
/// approximation for city-scale distances):
///   dx = (lng - h.long) * cos(h.lat * π/180) * 111320
///   dy = (lat - h.lat) * 110540
///
/// Containment uses the cube-coordinate approach for flat-top hexagons:
///   q = (2/3 * dx) / s
///   r = (-1/3 * dx + sqrt(3)/3 * dy) / s
/// Round to nearest cube coordinate; point is inside if the rounded cube
/// distance from origin is <= 1 (i.e., it maps to the (0,0,0) cube cell).
bool _pointInHexagon(Hexagon h, double lat, double lng) {
  final s = h.sideLength;
  if (s <= 0) return false;

  // Convert lat/lng offset to approximate meters
  final dx = (lng - h.long) * cos(h.lat * pi / 180) * 111320;
  final dy = (lat - h.lat) * 110540;

  // Fractional cube coordinates for flat-top hexagon
  final q = (2.0 / 3.0 * dx) / s;
  final r = (-1.0 / 3.0 * dx + sqrt(3) / 3.0 * dy) / s;
  final s3 = -q - r; // third cube coordinate (q + r + s3 == 0)

  // Round to nearest cube coordinate
  var rq = q.round().toDouble();
  var rr = r.round().toDouble();
  var rs = s3.round().toDouble();

  final dq = (rq - q).abs();
  final dr = (rr - r).abs();
  final ds = (rs - s3).abs();

  // Fix the component with the largest rounding error to maintain q+r+s==0
  if (dq > dr && dq > ds) {
    rq = -rr - rs;
  } else if (dr > ds) {
    rr = -rq - rs;
  } else {
    rs = -rq - rr;
  }

  // The point is inside the hexagon at the origin if the rounded cube
  // coordinate is (0, 0, 0)
  return rq == 0 && rr == 0 && rs == 0;
}
