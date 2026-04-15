// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hexagon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HexagonImpl _$$HexagonImplFromJson(Map<String, dynamic> json) =>
    _$HexagonImpl(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      sideLength: (json['sideLength'] as num).toDouble(),
      vendors:
          (json['vendors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HexagonImplToJson(_$HexagonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'long': instance.long,
      'sideLength': instance.sideLength,
      'vendors': instance.vendors,
    };
