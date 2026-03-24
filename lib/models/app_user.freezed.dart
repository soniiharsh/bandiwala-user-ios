// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppUser _$AppUserFromJson(Map<String, dynamic> json) {
  return _AppUser.fromJson(json);
}

/// @nodoc
mixin _$AppUser {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;
  List<SavedAddress> get savedAddresses => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppUserCopyWith<AppUser> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUserCopyWith<$Res> {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) then) =
      _$AppUserCopyWithImpl<$Res, AppUser>;
  @useResult
  $Res call({
    String uid,
    String name,
    String phone,
    String? fcmToken,
    List<SavedAddress> savedAddresses,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$AppUserCopyWithImpl<$Res, $Val extends AppUser>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? phone = null,
    Object? fcmToken = freezed,
    Object? savedAddresses = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            fcmToken: freezed == fcmToken
                ? _value.fcmToken
                : fcmToken // ignore: cast_nullable_to_non_nullable
                      as String?,
            savedAddresses: null == savedAddresses
                ? _value.savedAddresses
                : savedAddresses // ignore: cast_nullable_to_non_nullable
                      as List<SavedAddress>,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppUserImplCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$$AppUserImplCopyWith(
    _$AppUserImpl value,
    $Res Function(_$AppUserImpl) then,
  ) = __$$AppUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String name,
    String phone,
    String? fcmToken,
    List<SavedAddress> savedAddresses,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$AppUserImplCopyWithImpl<$Res>
    extends _$AppUserCopyWithImpl<$Res, _$AppUserImpl>
    implements _$$AppUserImplCopyWith<$Res> {
  __$$AppUserImplCopyWithImpl(
    _$AppUserImpl _value,
    $Res Function(_$AppUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? phone = null,
    Object? fcmToken = freezed,
    Object? savedAddresses = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$AppUserImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        fcmToken: freezed == fcmToken
            ? _value.fcmToken
            : fcmToken // ignore: cast_nullable_to_non_nullable
                  as String?,
        savedAddresses: null == savedAddresses
            ? _value._savedAddresses
            : savedAddresses // ignore: cast_nullable_to_non_nullable
                  as List<SavedAddress>,
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
class _$AppUserImpl extends _AppUser {
  const _$AppUserImpl({
    required this.uid,
    required this.name,
    required this.phone,
    this.fcmToken,
    final List<SavedAddress> savedAddresses = const [],
    this.createdAt,
  }) : _savedAddresses = savedAddresses,
       super._();

  factory _$AppUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppUserImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String? fcmToken;
  final List<SavedAddress> _savedAddresses;
  @override
  @JsonKey()
  List<SavedAddress> get savedAddresses {
    if (_savedAddresses is EqualUnmodifiableListView) return _savedAddresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_savedAddresses);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, phone: $phone, fcmToken: $fcmToken, savedAddresses: $savedAddresses, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            const DeepCollectionEquality().equals(
              other._savedAddresses,
              _savedAddresses,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    name,
    phone,
    fcmToken,
    const DeepCollectionEquality().hash(_savedAddresses),
    createdAt,
  );

  /// Create a copy of AppUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      __$$AppUserImplCopyWithImpl<_$AppUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppUserImplToJson(this);
  }
}

abstract class _AppUser extends AppUser {
  const factory _AppUser({
    required final String uid,
    required final String name,
    required final String phone,
    final String? fcmToken,
    final List<SavedAddress> savedAddresses,
    final DateTime? createdAt,
  }) = _$AppUserImpl;
  const _AppUser._() : super._();

  factory _AppUser.fromJson(Map<String, dynamic> json) = _$AppUserImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  String get phone;
  @override
  String? get fcmToken;
  @override
  List<SavedAddress> get savedAddresses;
  @override
  DateTime? get createdAt;

  /// Create a copy of AppUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SavedAddress _$SavedAddressFromJson(Map<String, dynamic> json) {
  return _SavedAddress.fromJson(json);
}

/// @nodoc
mixin _$SavedAddress {
  String get geolocation => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this SavedAddress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SavedAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SavedAddressCopyWith<SavedAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedAddressCopyWith<$Res> {
  factory $SavedAddressCopyWith(
    SavedAddress value,
    $Res Function(SavedAddress) then,
  ) = _$SavedAddressCopyWithImpl<$Res, SavedAddress>;
  @useResult
  $Res call({
    String geolocation,
    double latitude,
    double longitude,
    String phone,
    String? address,
    String? label,
  });
}

/// @nodoc
class _$SavedAddressCopyWithImpl<$Res, $Val extends SavedAddress>
    implements $SavedAddressCopyWith<$Res> {
  _$SavedAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SavedAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? geolocation = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? phone = null,
    Object? address = freezed,
    Object? label = freezed,
  }) {
    return _then(
      _value.copyWith(
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
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SavedAddressImplCopyWith<$Res>
    implements $SavedAddressCopyWith<$Res> {
  factory _$$SavedAddressImplCopyWith(
    _$SavedAddressImpl value,
    $Res Function(_$SavedAddressImpl) then,
  ) = __$$SavedAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String geolocation,
    double latitude,
    double longitude,
    String phone,
    String? address,
    String? label,
  });
}

/// @nodoc
class __$$SavedAddressImplCopyWithImpl<$Res>
    extends _$SavedAddressCopyWithImpl<$Res, _$SavedAddressImpl>
    implements _$$SavedAddressImplCopyWith<$Res> {
  __$$SavedAddressImplCopyWithImpl(
    _$SavedAddressImpl _value,
    $Res Function(_$SavedAddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SavedAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? geolocation = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? phone = null,
    Object? address = freezed,
    Object? label = freezed,
  }) {
    return _then(
      _$SavedAddressImpl(
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
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SavedAddressImpl extends _SavedAddress {
  const _$SavedAddressImpl({
    required this.geolocation,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.address,
    this.label,
  }) : super._();

  factory _$SavedAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$SavedAddressImplFromJson(json);

  @override
  final String geolocation;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String phone;
  @override
  final String? address;
  @override
  final String? label;

  @override
  String toString() {
    return 'SavedAddress(geolocation: $geolocation, latitude: $latitude, longitude: $longitude, phone: $phone, address: $address, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedAddressImpl &&
            (identical(other.geolocation, geolocation) ||
                other.geolocation == geolocation) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    geolocation,
    latitude,
    longitude,
    phone,
    address,
    label,
  );

  /// Create a copy of SavedAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedAddressImplCopyWith<_$SavedAddressImpl> get copyWith =>
      __$$SavedAddressImplCopyWithImpl<_$SavedAddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SavedAddressImplToJson(this);
  }
}

abstract class _SavedAddress extends SavedAddress {
  const factory _SavedAddress({
    required final String geolocation,
    required final double latitude,
    required final double longitude,
    required final String phone,
    final String? address,
    final String? label,
  }) = _$SavedAddressImpl;
  const _SavedAddress._() : super._();

  factory _SavedAddress.fromJson(Map<String, dynamic> json) =
      _$SavedAddressImpl.fromJson;

  @override
  String get geolocation;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get phone;
  @override
  String? get address;
  @override
  String? get label;

  /// Create a copy of SavedAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SavedAddressImplCopyWith<_$SavedAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
