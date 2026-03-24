// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VendorImpl _$$VendorImplFromJson(Map<String, dynamic> json) => _$VendorImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  fcmToken: json['fcmToken'] as String?,
  imageUrl: json['imageUrl'] as String? ?? '',
  address: json['address'] as String? ?? '',
  category: json['category'] as String? ?? '',
  isAvailable: json['isAvailable'] as bool? ?? false,
  rating: (json['rating'] as num?)?.toDouble() ?? 4.2,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$VendorImplToJson(_$VendorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'fcmToken': instance.fcmToken,
      'imageUrl': instance.imageUrl,
      'address': instance.address,
      'category': instance.category,
      'isAvailable': instance.isAvailable,
      'rating': instance.rating,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
