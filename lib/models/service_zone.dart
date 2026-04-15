import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_zone.freezed.dart';
part 'service_zone.g.dart';

@freezed
class ServiceZone with _$ServiceZone {
  const factory ServiceZone({
    required String id,
    required String name,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) = _ServiceZone;

  factory ServiceZone.fromJson(Map<String, dynamic> json) =>
      _$ServiceZoneFromJson(json);

  factory ServiceZone.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ServiceZone(
      id: doc.id,
      name: d['name'] ?? '',
      lat: (d['latitude'] as num).toDouble(),
      lng: (d['longitude'] as num).toDouble(),
      radiusMeters: (d['radius'] as num).toDouble(),
    );
  }
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

String? matchZone(List<ServiceZone> zones, double lat, double lng) {
  for (final z in zones) {
    if (haversineDistance(lat, lng, z.lat, z.lng) <= z.radiusMeters) {
      return z.name;
    }
  }
  return null;
}
