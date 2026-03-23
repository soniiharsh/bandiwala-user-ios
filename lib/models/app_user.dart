import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String? fcmToken;
  final List<SavedAddress> savedAddresses;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    this.fcmToken,
    this.savedAddresses = const [],
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      fcmToken: d['FCMToken'],
      savedAddresses: (d['savedAddresses'] as List<dynamic>? ?? [])
          .map((e) => SavedAddress.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  AppUser copyWith({
    String? name,
    String? fcmToken,
    List<SavedAddress>? savedAddresses,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      phone: phone,
      fcmToken: fcmToken ?? this.fcmToken,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      createdAt: createdAt,
    );
  }
}

class SavedAddress {
  final String geolocation; // Human-readable area name (was address)
  final double latitude;
  final double longitude;
  final String? address; // Specific house no / street (was houseNo)
  final String phone;
  final String? label;

  const SavedAddress({
    required this.geolocation,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.address,
    this.label,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> m) => SavedAddress(
    geolocation: m['geolocation'] ?? m['address'] ?? '',
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    phone: m['phone'] ?? '',
    address: m['address'] ?? m['houseNo'],
    label: m['label'],
  );

  Map<String, dynamic> toMap() => {
    'geolocation': geolocation,
    'latitude': latitude,
    'longitude': longitude,
    'address': address ?? '',
    'phone': phone,
    'label': label ?? 'Other',
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) =>
      SavedAddress.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  String get fullDisplay {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (geolocation.isNotEmpty) parts.add(geolocation);
    return parts.join(', ');
  }

  bool isSameLocation(SavedAddress other) {
    const double threshold = 0.0005;
    return (latitude - other.latitude).abs() < threshold &&
        (longitude - other.longitude).abs() < threshold;
  }

  String get coordinatesDisplay =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get shortLabel => label ?? 'Other';

  /// Convert to the format used by the top bar / picker if different.
  /// Now that they are consolidated, this might be redundant.
  Map<String, dynamic> toLocationJson() => toJson();
}
