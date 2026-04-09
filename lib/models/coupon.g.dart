// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CouponImpl _$$CouponImplFromJson(Map<String, dynamic> json) => _$CouponImpl(
  id: json['id'] as String,
  couponCode: json['couponCode'] as String,
  couponName: json['couponName'] as String,
  couponType: json['couponType'] as String,
  description: json['description'] as String,
  minAmount: (json['minAmount'] as num).toDouble(),
  maxDiscountableAmount: (json['maxDiscountableAmount'] as num).toInt(),
  discount: (json['discount'] as num).toDouble(),
  maxUsage: (json['maxUsage'] as num).toInt(),
  currentUsage: (json['currentUsage'] as num).toInt(),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  vendorId: json['vendorId'] as String? ?? '',
  perUserLimit: (json['perUserLimit'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CouponImplToJson(_$CouponImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'couponCode': instance.couponCode,
      'couponName': instance.couponName,
      'couponType': instance.couponType,
      'description': instance.description,
      'minAmount': instance.minAmount,
      'maxDiscountableAmount': instance.maxDiscountableAmount,
      'discount': instance.discount,
      'maxUsage': instance.maxUsage,
      'currentUsage': instance.currentUsage,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'vendorId': instance.vendorId,
      'perUserLimit': instance.perUserLimit,
    };
