// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      fcmToken: json['fcmToken'] as String?,
      savedAddresses:
          (json['savedAddresses'] as List<dynamic>?)
              ?.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'phone': instance.phone,
      'fcmToken': instance.fcmToken,
      'savedAddresses': instance.savedAddresses,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$SavedAddressImpl _$$SavedAddressImplFromJson(Map<String, dynamic> json) =>
    _$SavedAddressImpl(
      geolocation: json['geolocation'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      address: json['address'] as String?,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$$SavedAddressImplToJson(_$SavedAddressImpl instance) =>
    <String, dynamic>{
      'geolocation': instance.geolocation,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phone': instance.phone,
      'address': instance.address,
      'label': instance.label,
    };
