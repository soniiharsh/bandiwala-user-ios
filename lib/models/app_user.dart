import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required String name,
    required String phone,
    String? fcmToken,
    @Default([]) List<SavedAddress> savedAddresses,
    DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

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
}

@freezed
class SavedAddress with _$SavedAddress {
  const SavedAddress._();

  const factory SavedAddress({
    required String geolocation,
    required double latitude,
    required double longitude,
    required String phone,
    String? address,
    String? label,
  }) = _SavedAddress;

  factory SavedAddress.fromJson(Map<String, dynamic> json) =>
      _$SavedAddressFromJson(json);

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

  Map<String, dynamic> toLocationJson() => toMap();
}
