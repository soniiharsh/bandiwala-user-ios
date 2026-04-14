import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hexagon.freezed.dart';
part 'hexagon.g.dart';

@freezed
class Hexagon with _$Hexagon {
  const factory Hexagon({
    required String id,
    required double lat,
    required double long,
    required double sideLength,
    @Default([]) List<String> vendors,
  }) = _Hexagon;

  factory Hexagon.fromJson(Map<String, dynamic> json) =>
      _$HexagonFromJson(json);

  factory Hexagon.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Hexagon(
      id: doc.id,
      lat: (d['lat'] as num).toDouble(),
      long: (d['long'] as num).toDouble(),
      sideLength: (d['sideLength'] as num).toDouble(),
      vendors: List<String>.from(d['vendors'] as List? ?? []),
    );
  }
}
