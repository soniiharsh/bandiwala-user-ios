// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderDeliveryAddress _$OrderDeliveryAddressFromJson(Map<String, dynamic> json) {
  return _OrderDeliveryAddress.fromJson(json);
}

/// @nodoc
mixin _$OrderDeliveryAddress {
  String get address => throw _privateConstructorUsedError;
  String get geolocation => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this OrderDeliveryAddress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderDeliveryAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderDeliveryAddressCopyWith<OrderDeliveryAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderDeliveryAddressCopyWith<$Res> {
  factory $OrderDeliveryAddressCopyWith(
    OrderDeliveryAddress value,
    $Res Function(OrderDeliveryAddress) then,
  ) = _$OrderDeliveryAddressCopyWithImpl<$Res, OrderDeliveryAddress>;
  @useResult
  $Res call({
    String address,
    String geolocation,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class _$OrderDeliveryAddressCopyWithImpl<
  $Res,
  $Val extends OrderDeliveryAddress
>
    implements $OrderDeliveryAddressCopyWith<$Res> {
  _$OrderDeliveryAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderDeliveryAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? geolocation = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _value.copyWith(
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            geolocation: null == geolocation
                ? _value.geolocation
                : geolocation // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderDeliveryAddressImplCopyWith<$Res>
    implements $OrderDeliveryAddressCopyWith<$Res> {
  factory _$$OrderDeliveryAddressImplCopyWith(
    _$OrderDeliveryAddressImpl value,
    $Res Function(_$OrderDeliveryAddressImpl) then,
  ) = __$$OrderDeliveryAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String address,
    String geolocation,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class __$$OrderDeliveryAddressImplCopyWithImpl<$Res>
    extends _$OrderDeliveryAddressCopyWithImpl<$Res, _$OrderDeliveryAddressImpl>
    implements _$$OrderDeliveryAddressImplCopyWith<$Res> {
  __$$OrderDeliveryAddressImplCopyWithImpl(
    _$OrderDeliveryAddressImpl _value,
    $Res Function(_$OrderDeliveryAddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderDeliveryAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? geolocation = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _$OrderDeliveryAddressImpl(
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        geolocation: null == geolocation
            ? _value.geolocation
            : geolocation // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderDeliveryAddressImpl extends _OrderDeliveryAddress {
  const _$OrderDeliveryAddressImpl({
    required this.address,
    required this.geolocation,
    required this.latitude,
    required this.longitude,
  }) : super._();

  factory _$OrderDeliveryAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderDeliveryAddressImplFromJson(json);

  @override
  final String address;
  @override
  final String geolocation;
  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'OrderDeliveryAddress(address: $address, geolocation: $geolocation, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderDeliveryAddressImpl &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.geolocation, geolocation) ||
                other.geolocation == geolocation) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, address, geolocation, latitude, longitude);

  /// Create a copy of OrderDeliveryAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderDeliveryAddressImplCopyWith<_$OrderDeliveryAddressImpl>
  get copyWith =>
      __$$OrderDeliveryAddressImplCopyWithImpl<_$OrderDeliveryAddressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderDeliveryAddressImplToJson(this);
  }
}

abstract class _OrderDeliveryAddress extends OrderDeliveryAddress {
  const factory _OrderDeliveryAddress({
    required final String address,
    required final String geolocation,
    required final double latitude,
    required final double longitude,
  }) = _$OrderDeliveryAddressImpl;
  const _OrderDeliveryAddress._() : super._();

  factory _OrderDeliveryAddress.fromJson(Map<String, dynamic> json) =
      _$OrderDeliveryAddressImpl.fromJson;

  @override
  String get address;
  @override
  String get geolocation;
  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of OrderDeliveryAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderDeliveryAddressImplCopyWith<_$OrderDeliveryAddressImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call({String name, double price, int quantity});
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = null,
    Object? quantity = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
    _$OrderItemImpl value,
    $Res Function(_$OrderItemImpl) then,
  ) = __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, double price, int quantity});
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
    _$OrderItemImpl _value,
    $Res Function(_$OrderItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = null,
    Object? quantity = null,
  }) {
    return _then(
      _$OrderItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl extends _OrderItem {
  const _$OrderItemImpl({
    required this.name,
    required this.price,
    required this.quantity,
  }) : super._();

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  final String name;
  @override
  final double price;
  @override
  final int quantity;

  @override
  String toString() {
    return 'OrderItem(name: $name, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, price, quantity);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(this);
  }
}

abstract class _OrderItem extends OrderItem {
  const factory _OrderItem({
    required final String name,
    required final double price,
    required final int quantity,
  }) = _$OrderItemImpl;
  const _OrderItem._() : super._();

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  String get name;
  @override
  double get price;
  @override
  int get quantity;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VendorOrder _$VendorOrderFromJson(Map<String, dynamic> json) {
  return _VendorOrder.fromJson(json);
}

/// @nodoc
mixin _$VendorOrder {
  String get vendorName => throw _privateConstructorUsedError;
  Map<String, OrderItem> get items => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get statusUpdatedAt => throw _privateConstructorUsedError;

  /// Serializes this VendorOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VendorOrderCopyWith<VendorOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VendorOrderCopyWith<$Res> {
  factory $VendorOrderCopyWith(
    VendorOrder value,
    $Res Function(VendorOrder) then,
  ) = _$VendorOrderCopyWithImpl<$Res, VendorOrder>;
  @useResult
  $Res call({
    String vendorName,
    Map<String, OrderItem> items,
    String status,
    DateTime? statusUpdatedAt,
  });
}

/// @nodoc
class _$VendorOrderCopyWithImpl<$Res, $Val extends VendorOrder>
    implements $VendorOrderCopyWith<$Res> {
  _$VendorOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorName = null,
    Object? items = null,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            vendorName: null == vendorName
                ? _value.vendorName
                : vendorName // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as Map<String, OrderItem>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            statusUpdatedAt: freezed == statusUpdatedAt
                ? _value.statusUpdatedAt
                : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VendorOrderImplCopyWith<$Res>
    implements $VendorOrderCopyWith<$Res> {
  factory _$$VendorOrderImplCopyWith(
    _$VendorOrderImpl value,
    $Res Function(_$VendorOrderImpl) then,
  ) = __$$VendorOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String vendorName,
    Map<String, OrderItem> items,
    String status,
    DateTime? statusUpdatedAt,
  });
}

/// @nodoc
class __$$VendorOrderImplCopyWithImpl<$Res>
    extends _$VendorOrderCopyWithImpl<$Res, _$VendorOrderImpl>
    implements _$$VendorOrderImplCopyWith<$Res> {
  __$$VendorOrderImplCopyWithImpl(
    _$VendorOrderImpl _value,
    $Res Function(_$VendorOrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorName = null,
    Object? items = null,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
  }) {
    return _then(
      _$VendorOrderImpl(
        vendorName: null == vendorName
            ? _value.vendorName
            : vendorName // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as Map<String, OrderItem>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        statusUpdatedAt: freezed == statusUpdatedAt
            ? _value.statusUpdatedAt
            : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VendorOrderImpl extends _VendorOrder {
  const _$VendorOrderImpl({
    required this.vendorName,
    required final Map<String, OrderItem> items,
    this.status = 'pending',
    this.statusUpdatedAt,
  }) : _items = items,
       super._();

  factory _$VendorOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$VendorOrderImplFromJson(json);

  @override
  final String vendorName;
  final Map<String, OrderItem> _items;
  @override
  Map<String, OrderItem> get items {
    if (_items is EqualUnmodifiableMapView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_items);
  }

  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? statusUpdatedAt;

  @override
  String toString() {
    return 'VendorOrder(vendorName: $vendorName, items: $items, status: $status, statusUpdatedAt: $statusUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VendorOrderImpl &&
            (identical(other.vendorName, vendorName) ||
                other.vendorName == vendorName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusUpdatedAt, statusUpdatedAt) ||
                other.statusUpdatedAt == statusUpdatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    vendorName,
    const DeepCollectionEquality().hash(_items),
    status,
    statusUpdatedAt,
  );

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VendorOrderImplCopyWith<_$VendorOrderImpl> get copyWith =>
      __$$VendorOrderImplCopyWithImpl<_$VendorOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VendorOrderImplToJson(this);
  }
}

abstract class _VendorOrder extends VendorOrder {
  const factory _VendorOrder({
    required final String vendorName,
    required final Map<String, OrderItem> items,
    final String status,
    final DateTime? statusUpdatedAt,
  }) = _$VendorOrderImpl;
  const _VendorOrder._() : super._();

  factory _VendorOrder.fromJson(Map<String, dynamic> json) =
      _$VendorOrderImpl.fromJson;

  @override
  String get vendorName;
  @override
  Map<String, OrderItem> get items;
  @override
  String get status;
  @override
  DateTime? get statusUpdatedAt;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VendorOrderImplCopyWith<_$VendorOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppOrder _$AppOrderFromJson(Map<String, dynamic> json) {
  return _AppOrder.fromJson(json);
}

/// @nodoc
mixin _$AppOrder {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get customerPhone => throw _privateConstructorUsedError;
  OrderDeliveryAddress get deliveryAddress =>
      throw _privateConstructorUsedError;
  Map<String, VendorOrder> get itemsByVendor =>
      throw _privateConstructorUsedError;
  List<String> get vendorIds => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String get paymentId => throw _privateConstructorUsedError;
  double get deliveryFee => throw _privateConstructorUsedError;
  double get platformFee => throw _privateConstructorUsedError;
  double get foodTax => throw _privateConstructorUsedError;
  double get deliveryTax => throw _privateConstructorUsedError;
  bool get platformTax => throw _privateConstructorUsedError;
  bool get couponApplied => throw _privateConstructorUsedError;
  String get couponCode => throw _privateConstructorUsedError;
  String get couponType => throw _privateConstructorUsedError;
  double get couponDiscount => throw _privateConstructorUsedError;
  double get couponMaxDiscountableAmount => throw _privateConstructorUsedError;
  double get grandTotal => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get statusUpdatedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AppOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppOrderCopyWith<AppOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppOrderCopyWith<$Res> {
  factory $AppOrderCopyWith(AppOrder value, $Res Function(AppOrder) then) =
      _$AppOrderCopyWithImpl<$Res, AppOrder>;
  @useResult
  $Res call({
    String id,
    String userId,
    String customerPhone,
    OrderDeliveryAddress deliveryAddress,
    Map<String, VendorOrder> itemsByVendor,
    List<String> vendorIds,
    String paymentMethod,
    String paymentId,
    double deliveryFee,
    double platformFee,
    double foodTax,
    double deliveryTax,
    bool platformTax,
    bool couponApplied,
    String couponCode,
    String couponType,
    double couponDiscount,
    double couponMaxDiscountableAmount,
    double grandTotal,
    String status,
    DateTime? statusUpdatedAt,
    DateTime? createdAt,
  });

  $OrderDeliveryAddressCopyWith<$Res> get deliveryAddress;
}

/// @nodoc
class _$AppOrderCopyWithImpl<$Res, $Val extends AppOrder>
    implements $AppOrderCopyWith<$Res> {
  _$AppOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerPhone = null,
    Object? deliveryAddress = null,
    Object? itemsByVendor = null,
    Object? vendorIds = null,
    Object? paymentMethod = null,
    Object? paymentId = null,
    Object? deliveryFee = null,
    Object? platformFee = null,
    Object? foodTax = null,
    Object? deliveryTax = null,
    Object? platformTax = null,
    Object? couponApplied = null,
    Object? couponCode = null,
    Object? couponType = null,
    Object? couponDiscount = null,
    Object? couponMaxDiscountableAmount = null,
    Object? grandTotal = null,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerPhone: null == customerPhone
                ? _value.customerPhone
                : customerPhone // ignore: cast_nullable_to_non_nullable
                      as String,
            deliveryAddress: null == deliveryAddress
                ? _value.deliveryAddress
                : deliveryAddress // ignore: cast_nullable_to_non_nullable
                      as OrderDeliveryAddress,
            itemsByVendor: null == itemsByVendor
                ? _value.itemsByVendor
                : itemsByVendor // ignore: cast_nullable_to_non_nullable
                      as Map<String, VendorOrder>,
            vendorIds: null == vendorIds
                ? _value.vendorIds
                : vendorIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentId: null == paymentId
                ? _value.paymentId
                : paymentId // ignore: cast_nullable_to_non_nullable
                      as String,
            deliveryFee: null == deliveryFee
                ? _value.deliveryFee
                : deliveryFee // ignore: cast_nullable_to_non_nullable
                      as double,
            platformFee: null == platformFee
                ? _value.platformFee
                : platformFee // ignore: cast_nullable_to_non_nullable
                      as double,
            foodTax: null == foodTax
                ? _value.foodTax
                : foodTax // ignore: cast_nullable_to_non_nullable
                      as double,
            deliveryTax: null == deliveryTax
                ? _value.deliveryTax
                : deliveryTax // ignore: cast_nullable_to_non_nullable
                      as double,
            platformTax: null == platformTax
                ? _value.platformTax
                : platformTax // ignore: cast_nullable_to_non_nullable
                      as bool,
            couponApplied: null == couponApplied
                ? _value.couponApplied
                : couponApplied // ignore: cast_nullable_to_non_nullable
                      as bool,
            couponCode: null == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String,
            couponType: null == couponType
                ? _value.couponType
                : couponType // ignore: cast_nullable_to_non_nullable
                      as String,
            couponDiscount: null == couponDiscount
                ? _value.couponDiscount
                : couponDiscount // ignore: cast_nullable_to_non_nullable
                      as double,
            couponMaxDiscountableAmount: null == couponMaxDiscountableAmount
                ? _value.couponMaxDiscountableAmount
                : couponMaxDiscountableAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            grandTotal: null == grandTotal
                ? _value.grandTotal
                : grandTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            statusUpdatedAt: freezed == statusUpdatedAt
                ? _value.statusUpdatedAt
                : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OrderDeliveryAddressCopyWith<$Res> get deliveryAddress {
    return $OrderDeliveryAddressCopyWith<$Res>(_value.deliveryAddress, (value) {
      return _then(_value.copyWith(deliveryAddress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppOrderImplCopyWith<$Res>
    implements $AppOrderCopyWith<$Res> {
  factory _$$AppOrderImplCopyWith(
    _$AppOrderImpl value,
    $Res Function(_$AppOrderImpl) then,
  ) = __$$AppOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String customerPhone,
    OrderDeliveryAddress deliveryAddress,
    Map<String, VendorOrder> itemsByVendor,
    List<String> vendorIds,
    String paymentMethod,
    String paymentId,
    double deliveryFee,
    double platformFee,
    double foodTax,
    double deliveryTax,
    bool platformTax,
    bool couponApplied,
    String couponCode,
    String couponType,
    double couponDiscount,
    double couponMaxDiscountableAmount,
    double grandTotal,
    String status,
    DateTime? statusUpdatedAt,
    DateTime? createdAt,
  });

  @override
  $OrderDeliveryAddressCopyWith<$Res> get deliveryAddress;
}

/// @nodoc
class __$$AppOrderImplCopyWithImpl<$Res>
    extends _$AppOrderCopyWithImpl<$Res, _$AppOrderImpl>
    implements _$$AppOrderImplCopyWith<$Res> {
  __$$AppOrderImplCopyWithImpl(
    _$AppOrderImpl _value,
    $Res Function(_$AppOrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? customerPhone = null,
    Object? deliveryAddress = null,
    Object? itemsByVendor = null,
    Object? vendorIds = null,
    Object? paymentMethod = null,
    Object? paymentId = null,
    Object? deliveryFee = null,
    Object? platformFee = null,
    Object? foodTax = null,
    Object? deliveryTax = null,
    Object? platformTax = null,
    Object? couponApplied = null,
    Object? couponCode = null,
    Object? couponType = null,
    Object? couponDiscount = null,
    Object? couponMaxDiscountableAmount = null,
    Object? grandTotal = null,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$AppOrderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerPhone: null == customerPhone
            ? _value.customerPhone
            : customerPhone // ignore: cast_nullable_to_non_nullable
                  as String,
        deliveryAddress: null == deliveryAddress
            ? _value.deliveryAddress
            : deliveryAddress // ignore: cast_nullable_to_non_nullable
                  as OrderDeliveryAddress,
        itemsByVendor: null == itemsByVendor
            ? _value._itemsByVendor
            : itemsByVendor // ignore: cast_nullable_to_non_nullable
                  as Map<String, VendorOrder>,
        vendorIds: null == vendorIds
            ? _value._vendorIds
            : vendorIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentId: null == paymentId
            ? _value.paymentId
            : paymentId // ignore: cast_nullable_to_non_nullable
                  as String,
        deliveryFee: null == deliveryFee
            ? _value.deliveryFee
            : deliveryFee // ignore: cast_nullable_to_non_nullable
                  as double,
        platformFee: null == platformFee
            ? _value.platformFee
            : platformFee // ignore: cast_nullable_to_non_nullable
                  as double,
        foodTax: null == foodTax
            ? _value.foodTax
            : foodTax // ignore: cast_nullable_to_non_nullable
                  as double,
        deliveryTax: null == deliveryTax
            ? _value.deliveryTax
            : deliveryTax // ignore: cast_nullable_to_non_nullable
                  as double,
        platformTax: null == platformTax
            ? _value.platformTax
            : platformTax // ignore: cast_nullable_to_non_nullable
                  as bool,
        couponApplied: null == couponApplied
            ? _value.couponApplied
            : couponApplied // ignore: cast_nullable_to_non_nullable
                  as bool,
        couponCode: null == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String,
        couponType: null == couponType
            ? _value.couponType
            : couponType // ignore: cast_nullable_to_non_nullable
                  as String,
        couponDiscount: null == couponDiscount
            ? _value.couponDiscount
            : couponDiscount // ignore: cast_nullable_to_non_nullable
                  as double,
        couponMaxDiscountableAmount: null == couponMaxDiscountableAmount
            ? _value.couponMaxDiscountableAmount
            : couponMaxDiscountableAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        grandTotal: null == grandTotal
            ? _value.grandTotal
            : grandTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        statusUpdatedAt: freezed == statusUpdatedAt
            ? _value.statusUpdatedAt
            : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppOrderImpl extends _AppOrder {
  const _$AppOrderImpl({
    required this.id,
    required this.userId,
    required this.customerPhone,
    required this.deliveryAddress,
    required final Map<String, VendorOrder> itemsByVendor,
    required final List<String> vendorIds,
    required this.paymentMethod,
    required this.paymentId,
    required this.deliveryFee,
    required this.platformFee,
    required this.foodTax,
    required this.deliveryTax,
    required this.platformTax,
    this.couponApplied = false,
    this.couponCode = '',
    this.couponType = '',
    this.couponDiscount = 0,
    this.couponMaxDiscountableAmount = 0,
    required this.grandTotal,
    required this.status,
    this.statusUpdatedAt,
    this.createdAt,
  }) : _itemsByVendor = itemsByVendor,
       _vendorIds = vendorIds,
       super._();

  factory _$AppOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String customerPhone;
  @override
  final OrderDeliveryAddress deliveryAddress;
  final Map<String, VendorOrder> _itemsByVendor;
  @override
  Map<String, VendorOrder> get itemsByVendor {
    if (_itemsByVendor is EqualUnmodifiableMapView) return _itemsByVendor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_itemsByVendor);
  }

  final List<String> _vendorIds;
  @override
  List<String> get vendorIds {
    if (_vendorIds is EqualUnmodifiableListView) return _vendorIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vendorIds);
  }

  @override
  final String paymentMethod;
  @override
  final String paymentId;
  @override
  final double deliveryFee;
  @override
  final double platformFee;
  @override
  final double foodTax;
  @override
  final double deliveryTax;
  @override
  final bool platformTax;
  @override
  @JsonKey()
  final bool couponApplied;
  @override
  @JsonKey()
  final String couponCode;
  @override
  @JsonKey()
  final String couponType;
  @override
  @JsonKey()
  final double couponDiscount;
  @override
  @JsonKey()
  final double couponMaxDiscountableAmount;
  @override
  final double grandTotal;
  @override
  final String status;
  @override
  final DateTime? statusUpdatedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AppOrder(id: $id, userId: $userId, customerPhone: $customerPhone, deliveryAddress: $deliveryAddress, itemsByVendor: $itemsByVendor, vendorIds: $vendorIds, paymentMethod: $paymentMethod, paymentId: $paymentId, deliveryFee: $deliveryFee, platformFee: $platformFee, foodTax: $foodTax, deliveryTax: $deliveryTax, platformTax: $platformTax, couponApplied: $couponApplied, couponCode: $couponCode, couponType: $couponType, couponDiscount: $couponDiscount, couponMaxDiscountableAmount: $couponMaxDiscountableAmount, grandTotal: $grandTotal, status: $status, statusUpdatedAt: $statusUpdatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            const DeepCollectionEquality().equals(
              other._itemsByVendor,
              _itemsByVendor,
            ) &&
            const DeepCollectionEquality().equals(
              other._vendorIds,
              _vendorIds,
            ) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee) &&
            (identical(other.platformFee, platformFee) ||
                other.platformFee == platformFee) &&
            (identical(other.foodTax, foodTax) || other.foodTax == foodTax) &&
            (identical(other.deliveryTax, deliveryTax) ||
                other.deliveryTax == deliveryTax) &&
            (identical(other.platformTax, platformTax) ||
                other.platformTax == platformTax) &&
            (identical(other.couponApplied, couponApplied) ||
                other.couponApplied == couponApplied) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.couponType, couponType) ||
                other.couponType == couponType) &&
            (identical(other.couponDiscount, couponDiscount) ||
                other.couponDiscount == couponDiscount) &&
            (identical(
                  other.couponMaxDiscountableAmount,
                  couponMaxDiscountableAmount,
                ) ||
                other.couponMaxDiscountableAmount ==
                    couponMaxDiscountableAmount) &&
            (identical(other.grandTotal, grandTotal) ||
                other.grandTotal == grandTotal) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusUpdatedAt, statusUpdatedAt) ||
                other.statusUpdatedAt == statusUpdatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    userId,
    customerPhone,
    deliveryAddress,
    const DeepCollectionEquality().hash(_itemsByVendor),
    const DeepCollectionEquality().hash(_vendorIds),
    paymentMethod,
    paymentId,
    deliveryFee,
    platformFee,
    foodTax,
    deliveryTax,
    platformTax,
    couponApplied,
    couponCode,
    couponType,
    couponDiscount,
    couponMaxDiscountableAmount,
    grandTotal,
    status,
    statusUpdatedAt,
    createdAt,
  ]);

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppOrderImplCopyWith<_$AppOrderImpl> get copyWith =>
      __$$AppOrderImplCopyWithImpl<_$AppOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppOrderImplToJson(this);
  }
}

abstract class _AppOrder extends AppOrder {
  const factory _AppOrder({
    required final String id,
    required final String userId,
    required final String customerPhone,
    required final OrderDeliveryAddress deliveryAddress,
    required final Map<String, VendorOrder> itemsByVendor,
    required final List<String> vendorIds,
    required final String paymentMethod,
    required final String paymentId,
    required final double deliveryFee,
    required final double platformFee,
    required final double foodTax,
    required final double deliveryTax,
    required final bool platformTax,
    final bool couponApplied,
    final String couponCode,
    final String couponType,
    final double couponDiscount,
    final double couponMaxDiscountableAmount,
    required final double grandTotal,
    required final String status,
    final DateTime? statusUpdatedAt,
    final DateTime? createdAt,
  }) = _$AppOrderImpl;
  const _AppOrder._() : super._();

  factory _AppOrder.fromJson(Map<String, dynamic> json) =
      _$AppOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get customerPhone;
  @override
  OrderDeliveryAddress get deliveryAddress;
  @override
  Map<String, VendorOrder> get itemsByVendor;
  @override
  List<String> get vendorIds;
  @override
  String get paymentMethod;
  @override
  String get paymentId;
  @override
  double get deliveryFee;
  @override
  double get platformFee;
  @override
  double get foodTax;
  @override
  double get deliveryTax;
  @override
  bool get platformTax;
  @override
  bool get couponApplied;
  @override
  String get couponCode;
  @override
  String get couponType;
  @override
  double get couponDiscount;
  @override
  double get couponMaxDiscountableAmount;
  @override
  double get grandTotal;
  @override
  String get status;
  @override
  DateTime? get statusUpdatedAt;
  @override
  DateTime? get createdAt;

  /// Create a copy of AppOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppOrderImplCopyWith<_$AppOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
