// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceZoneImpl _$$ServiceZoneImplFromJson(Map<String, dynamic> json) =>
    _$ServiceZoneImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
    );

Map<String, dynamic> _$$ServiceZoneImplToJson(_$ServiceZoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'lat': instance.lat,
      'lng': instance.lng,
      'radiusMeters': instance.radiusMeters,
    };
