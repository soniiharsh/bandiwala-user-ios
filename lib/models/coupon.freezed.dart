// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coupon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Coupon _$CouponFromJson(Map<String, dynamic> json) {
  return _Coupon.fromJson(json);
}

/// @nodoc
mixin _$Coupon {
  String get id => throw _privateConstructorUsedError;
  String get couponCode => throw _privateConstructorUsedError;
  String get couponName => throw _privateConstructorUsedError;
  String get couponType =>
      throw _privateConstructorUsedError; // "discount" | "free_delivery" | "flat_off"
  String get description => throw _privateConstructorUsedError;
  double get minAmount => throw _privateConstructorUsedError;
  int get maxDiscountableAmount => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  int get maxUsage => throw _privateConstructorUsedError;
  int get currentUsage => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get vendorId => throw _privateConstructorUsedError;
  int get perUserLimit => throw _privateConstructorUsedError;
  bool get secret => throw _privateConstructorUsedError;

  /// Serializes this Coupon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CouponCopyWith<Coupon> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CouponCopyWith<$Res> {
  factory $CouponCopyWith(Coupon value, $Res Function(Coupon) then) =
      _$CouponCopyWithImpl<$Res, Coupon>;
  @useResult
  $Res call({
    String id,
    String couponCode,
    String couponName,
    String couponType,
    String description,
    double minAmount,
    int maxDiscountableAmount,
    double discount,
    int maxUsage,
    int currentUsage,
    bool isActive,
    DateTime createdAt,
    String vendorId,
    int perUserLimit,
    bool secret,
  });
}

/// @nodoc
class _$CouponCopyWithImpl<$Res, $Val extends Coupon>
    implements $CouponCopyWith<$Res> {
  _$CouponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? couponCode = null,
    Object? couponName = null,
    Object? couponType = null,
    Object? description = null,
    Object? minAmount = null,
    Object? maxDiscountableAmount = null,
    Object? discount = null,
    Object? maxUsage = null,
    Object? currentUsage = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? vendorId = null,
    Object? perUserLimit = null,
    Object? secret = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            couponCode: null == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String,
            couponName: null == couponName
                ? _value.couponName
                : couponName // ignore: cast_nullable_to_non_nullable
                      as String,
            couponType: null == couponType
                ? _value.couponType
                : couponType // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            minAmount: null == minAmount
                ? _value.minAmount
                : minAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            maxDiscountableAmount: null == maxDiscountableAmount
                ? _value.maxDiscountableAmount
                : maxDiscountableAmount // ignore: cast_nullable_to_non_nullable
                      as int,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as double,
            maxUsage: null == maxUsage
                ? _value.maxUsage
                : maxUsage // ignore: cast_nullable_to_non_nullable
                      as int,
            currentUsage: null == currentUsage
                ? _value.currentUsage
                : currentUsage // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            vendorId: null == vendorId
                ? _value.vendorId
                : vendorId // ignore: cast_nullable_to_non_nullable
                      as String,
            perUserLimit: null == perUserLimit
                ? _value.perUserLimit
                : perUserLimit // ignore: cast_nullable_to_non_nullable
                      as int,
            secret: null == secret
                ? _value.secret
                : secret // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CouponImplCopyWith<$Res> implements $CouponCopyWith<$Res> {
  factory _$$CouponImplCopyWith(
    _$CouponImpl value,
    $Res Function(_$CouponImpl) then,
  ) = __$$CouponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String couponCode,
    String couponName,
    String couponType,
    String description,
    double minAmount,
    int maxDiscountableAmount,
    double discount,
    int maxUsage,
    int currentUsage,
    bool isActive,
    DateTime createdAt,
    String vendorId,
    int perUserLimit,
    bool secret,
  });
}

/// @nodoc
class __$$CouponImplCopyWithImpl<$Res>
    extends _$CouponCopyWithImpl<$Res, _$CouponImpl>
    implements _$$CouponImplCopyWith<$Res> {
  __$$CouponImplCopyWithImpl(
    _$CouponImpl _value,
    $Res Function(_$CouponImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? couponCode = null,
    Object? couponName = null,
    Object? couponType = null,
    Object? description = null,
    Object? minAmount = null,
    Object? maxDiscountableAmount = null,
    Object? discount = null,
    Object? maxUsage = null,
    Object? currentUsage = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? vendorId = null,
    Object? perUserLimit = null,
    Object? secret = null,
  }) {
    return _then(
      _$CouponImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        couponCode: null == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String,
        couponName: null == couponName
            ? _value.couponName
            : couponName // ignore: cast_nullable_to_non_nullable
                  as String,
        couponType: null == couponType
            ? _value.couponType
            : couponType // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        minAmount: null == minAmount
            ? _value.minAmount
            : minAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        maxDiscountableAmount: null == maxDiscountableAmount
            ? _value.maxDiscountableAmount
            : maxDiscountableAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as double,
        maxUsage: null == maxUsage
            ? _value.maxUsage
            : maxUsage // ignore: cast_nullable_to_non_nullable
                  as int,
        currentUsage: null == currentUsage
            ? _value.currentUsage
            : currentUsage // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        vendorId: null == vendorId
            ? _value.vendorId
            : vendorId // ignore: cast_nullable_to_non_nullable
                  as String,
        perUserLimit: null == perUserLimit
            ? _value.perUserLimit
            : perUserLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        secret: null == secret
            ? _value.secret
            : secret // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CouponImpl extends _Coupon {
  const _$CouponImpl({
    required this.id,
    required this.couponCode,
    required this.couponName,
    required this.couponType,
    required this.description,
    required this.minAmount,
    required this.maxDiscountableAmount,
    required this.discount,
    required this.maxUsage,
    required this.currentUsage,
    required this.isActive,
    required this.createdAt,
    this.vendorId = '',
    this.perUserLimit = 0,
    this.secret = false,
  }) : super._();

  factory _$CouponImpl.fromJson(Map<String, dynamic> json) =>
      _$$CouponImplFromJson(json);

  @override
  final String id;
  @override
  final String couponCode;
  @override
  final String couponName;
  @override
  final String couponType;
  // "discount" | "free_delivery" | "flat_off"
  @override
  final String description;
  @override
  final double minAmount;
  @override
  final int maxDiscountableAmount;
  @override
  final double discount;
  @override
  final int maxUsage;
  @override
  final int currentUsage;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final String vendorId;
  @override
  @JsonKey()
  final int perUserLimit;
  @override
  @JsonKey()
  final bool secret;

  @override
  String toString() {
    return 'Coupon(id: $id, couponCode: $couponCode, couponName: $couponName, couponType: $couponType, description: $description, minAmount: $minAmount, maxDiscountableAmount: $maxDiscountableAmount, discount: $discount, maxUsage: $maxUsage, currentUsage: $currentUsage, isActive: $isActive, createdAt: $createdAt, vendorId: $vendorId, perUserLimit: $perUserLimit, secret: $secret)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CouponImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.couponName, couponName) ||
                other.couponName == couponName) &&
            (identical(other.couponType, couponType) ||
                other.couponType == couponType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount) &&
            (identical(other.maxDiscountableAmount, maxDiscountableAmount) ||
                other.maxDiscountableAmount == maxDiscountableAmount) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.maxUsage, maxUsage) ||
                other.maxUsage == maxUsage) &&
            (identical(other.currentUsage, currentUsage) ||
                other.currentUsage == currentUsage) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.perUserLimit, perUserLimit) ||
                other.perUserLimit == perUserLimit) &&
            (identical(other.secret, secret) || other.secret == secret));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    couponCode,
    couponName,
    couponType,
    description,
    minAmount,
    maxDiscountableAmount,
    discount,
    maxUsage,
    currentUsage,
    isActive,
    createdAt,
    vendorId,
    perUserLimit,
    secret,
  );

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      __$$CouponImplCopyWithImpl<_$CouponImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CouponImplToJson(this);
  }
}

abstract class _Coupon extends Coupon {
  const factory _Coupon({
    required final String id,
    required final String couponCode,
    required final String couponName,
    required final String couponType,
    required final String description,
    required final double minAmount,
    required final int maxDiscountableAmount,
    required final double discount,
    required final int maxUsage,
    required final int currentUsage,
    required final bool isActive,
    required final DateTime createdAt,
    final String vendorId,
    final int perUserLimit,
    final bool secret,
  }) = _$CouponImpl;
  const _Coupon._() : super._();

  factory _Coupon.fromJson(Map<String, dynamic> json) = _$CouponImpl.fromJson;

  @override
  String get id;
  @override
  String get couponCode;
  @override
  String get couponName;
  @override
  String get couponType; // "discount" | "free_delivery" | "flat_off"
  @override
  String get description;
  @override
  double get minAmount;
  @override
  int get maxDiscountableAmount;
  @override
  double get discount;
  @override
  int get maxUsage;
  @override
  int get currentUsage;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override
  String get vendorId;
  @override
  int get perUserLimit;
  @override
  bool get secret;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
