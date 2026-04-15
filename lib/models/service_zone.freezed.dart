// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_zone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ServiceZone _$ServiceZoneFromJson(Map<String, dynamic> json) {
  return _ServiceZone.fromJson(json);
}

/// @nodoc
mixin _$ServiceZone {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  double get radiusMeters => throw _privateConstructorUsedError;

  /// Serializes this ServiceZone to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceZoneCopyWith<ServiceZone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceZoneCopyWith<$Res> {
  factory $ServiceZoneCopyWith(
    ServiceZone value,
    $Res Function(ServiceZone) then,
  ) = _$ServiceZoneCopyWithImpl<$Res, ServiceZone>;
  @useResult
  $Res call({
    String id,
    String name,
    double lat,
    double lng,
    double radiusMeters,
  });
}

/// @nodoc
class _$ServiceZoneCopyWithImpl<$Res, $Val extends ServiceZone>
    implements $ServiceZoneCopyWith<$Res> {
  _$ServiceZoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? lat = null,
    Object? lng = null,
    Object? radiusMeters = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            lng: null == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double,
            radiusMeters: null == radiusMeters
                ? _value.radiusMeters
                : radiusMeters // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceZoneImplCopyWith<$Res>
    implements $ServiceZoneCopyWith<$Res> {
  factory _$$ServiceZoneImplCopyWith(
    _$ServiceZoneImpl value,
    $Res Function(_$ServiceZoneImpl) then,
  ) = __$$ServiceZoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double lat,
    double lng,
    double radiusMeters,
  });
}

/// @nodoc
class __$$ServiceZoneImplCopyWithImpl<$Res>
    extends _$ServiceZoneCopyWithImpl<$Res, _$ServiceZoneImpl>
    implements _$$ServiceZoneImplCopyWith<$Res> {
  __$$ServiceZoneImplCopyWithImpl(
    _$ServiceZoneImpl _value,
    $Res Function(_$ServiceZoneImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? lat = null,
    Object? lng = null,
    Object? radiusMeters = null,
  }) {
    return _then(
      _$ServiceZoneImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        lng: null == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double,
        radiusMeters: null == radiusMeters
            ? _value.radiusMeters
            : radiusMeters // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceZoneImpl implements _ServiceZone {
  const _$ServiceZoneImpl({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory _$ServiceZoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceZoneImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final double radiusMeters;

  @override
  String toString() {
    return 'ServiceZone(id: $id, name: $name, lat: $lat, lng: $lng, radiusMeters: $radiusMeters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceZoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.radiusMeters, radiusMeters) ||
                other.radiusMeters == radiusMeters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, lat, lng, radiusMeters);

  /// Create a copy of ServiceZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceZoneImplCopyWith<_$ServiceZoneImpl> get copyWith =>
      __$$ServiceZoneImplCopyWithImpl<_$ServiceZoneImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceZoneImplToJson(this);
  }
}

abstract class _ServiceZone implements ServiceZone {
  const factory _ServiceZone({
    required final String id,
    required final String name,
    required final double lat,
    required final double lng,
    required final double radiusMeters,
  }) = _$ServiceZoneImpl;

  factory _ServiceZone.fromJson(Map<String, dynamic> json) =
      _$ServiceZoneImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get lat;
  @override
  double get lng;
  @override
  double get radiusMeters;

  /// Create a copy of ServiceZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceZoneImplCopyWith<_$ServiceZoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
