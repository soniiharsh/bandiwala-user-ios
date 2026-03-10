import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceZone {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  const ServiceZone({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });
}

const List<ServiceZone> kServiceZones = [
  ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.476388,
    lng: 78.390350,
    radiusMeters: 805.83,
  ),
  ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.485210,
    lng: 78.376959,
    radiusMeters: 941.10,
  ),
  ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.490998,
    lng: 78.393568,
    radiusMeters: 1020.00,
  ),
  ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.493208,
    lng: 78.383281,
    radiusMeters: 750.00,
  ),
  ServiceZone(
    name: 'Madhapur',
    lat: 17.446960,
    lng: 78.391101,
    radiusMeters: 1225.23,
  ),
  ServiceZone(
    name: 'Nizampet',
    lat: 17.509248,
    lng: 78.373744,
    radiusMeters: 1471.04,
  ),
  ServiceZone(
    name: 'Pragathi Nagar',
    lat: 17.522838,
    lng: 78.396081,
    radiusMeters: 1380.00,
  ),
  ServiceZone(
    name: 'Addagutta',
    lat: 17.503804,
    lng: 78.396080,
    radiusMeters: 1029.53,
  ),
  ServiceZone(
    name: 'Gajularamaram',
    lat: 17.536753,
    lng: 78.396639,
    radiusMeters: 491.73,
  ),
];

Future<List<ServiceZone>> fetchServiceZones() async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('settings')
        .doc('service_zones');
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      final defaultZones = kServiceZones
          .map(
            (z) => {
              'name': z.name,
              'lat': z.lat,
              'lng': z.lng,
              'radiusMeters': z.radiusMeters,
            },
          )
          .toList();
      await docRef.set({'zones': defaultZones});
      return List.from(kServiceZones);
    } else {
      final data = docSnap.data()!;
      if (data.containsKey('zones')) {
        final zonesList = data['zones'] as List;
        return zonesList
            .map(
              (z) => ServiceZone(
                name: z['name'],
                lat: (z['lat'] as num).toDouble(),
                lng: (z['lng'] as num).toDouble(),
                radiusMeters: (z['radiusMeters'] as num).toDouble(),
              ),
            )
            .toList();
      }
    }
  } catch (e) {
    print('Error fetching service zones: $e');
  }
  return List.from(kServiceZones);
}
