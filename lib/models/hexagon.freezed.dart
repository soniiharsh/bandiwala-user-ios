// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hexagon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Hexagon _$HexagonFromJson(Map<String, dynamic> json) {
  return _Hexagon.fromJson(json);
}

/// @nodoc
mixin _$Hexagon {
  String get id => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get long => throw _privateConstructorUsedError;
  double get sideLength => throw _privateConstructorUsedError;
  List<String> get vendors => throw _privateConstructorUsedError;

  /// Serializes this Hexagon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hexagon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HexagonCopyWith<Hexagon> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HexagonCopyWith<$Res> {
  factory $HexagonCopyWith(Hexagon value, $Res Function(Hexagon) then) =
      _$HexagonCopyWithImpl<$Res, Hexagon>;
  @useResult
  $Res call({
    String id,
    double lat,
    double long,
    double sideLength,
    List<String> vendors,
  });
}

/// @nodoc
class _$HexagonCopyWithImpl<$Res, $Val extends Hexagon>
    implements $HexagonCopyWith<$Res> {
  _$HexagonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hexagon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? long = null,
    Object? sideLength = null,
    Object? vendors = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            long: null == long
                ? _value.long
                : long // ignore: cast_nullable_to_non_nullable
                      as double,
            sideLength: null == sideLength
                ? _value.sideLength
                : sideLength // ignore: cast_nullable_to_non_nullable
                      as double,
            vendors: null == vendors
                ? _value.vendors
                : vendors // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HexagonImplCopyWith<$Res> implements $HexagonCopyWith<$Res> {
  factory _$$HexagonImplCopyWith(
    _$HexagonImpl value,
    $Res Function(_$HexagonImpl) then,
  ) = __$$HexagonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    double lat,
    double long,
    double sideLength,
    List<String> vendors,
  });
}

/// @nodoc
class __$$HexagonImplCopyWithImpl<$Res>
    extends _$HexagonCopyWithImpl<$Res, _$HexagonImpl>
    implements _$$HexagonImplCopyWith<$Res> {
  __$$HexagonImplCopyWithImpl(
    _$HexagonImpl _value,
    $Res Function(_$HexagonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Hexagon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? long = null,
    Object? sideLength = null,
    Object? vendors = null,
  }) {
    return _then(
      _$HexagonImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        long: null == long
            ? _value.long
            : long // ignore: cast_nullable_to_non_nullable
                  as double,
        sideLength: null == sideLength
            ? _value.sideLength
            : sideLength // ignore: cast_nullable_to_non_nullable
                  as double,
        vendors: null == vendors
            ? _value._vendors
            : vendors // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HexagonImpl implements _Hexagon {
  const _$HexagonImpl({
    required this.id,
    required this.lat,
    required this.long,
    required this.sideLength,
    final List<String> vendors = const [],
  }) : _vendors = vendors;

  factory _$HexagonImpl.fromJson(Map<String, dynamic> json) =>
      _$$HexagonImplFromJson(json);

  @override
  final String id;
  @override
  final double lat;
  @override
  final double long;
  @override
  final double sideLength;
  final List<String> _vendors;
  @override
  @JsonKey()
  List<String> get vendors {
    if (_vendors is EqualUnmodifiableListView) return _vendors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vendors);
  }

  @override
  String toString() {
    return 'Hexagon(id: $id, lat: $lat, long: $long, sideLength: $sideLength, vendors: $vendors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HexagonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.long, long) || other.long == long) &&
            (identical(other.sideLength, sideLength) ||
                other.sideLength == sideLength) &&
            const DeepCollectionEquality().equals(other._vendors, _vendors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    lat,
    long,
    sideLength,
    const DeepCollectionEquality().hash(_vendors),
  );

  /// Create a copy of Hexagon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HexagonImplCopyWith<_$HexagonImpl> get copyWith =>
      __$$HexagonImplCopyWithImpl<_$HexagonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HexagonImplToJson(this);
  }
}

abstract class _Hexagon implements Hexagon {
  const factory _Hexagon({
    required final String id,
    required final double lat,
    required final double long,
    required final double sideLength,
    final List<String> vendors,
  }) = _$HexagonImpl;

  factory _Hexagon.fromJson(Map<String, dynamic> json) = _$HexagonImpl.fromJson;

  @override
  String get id;
  @override
  double get lat;
  @override
  double get long;
  @override
  double get sideLength;
  @override
  List<String> get vendors;

  /// Create a copy of Hexagon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HexagonImplCopyWith<_$HexagonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
