import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String vendorId,
    required String name,
    @Default('') String description,
    required double price,
    @Default('') String imageUrl,
    @Default('') String category,
    @Default([]) List<String> tags,
    @Default([]) List<Map<String, dynamic>> options,
    @Default([]) List<Map<String, dynamic>> addons,
    @Default(true) bool isVeg,
    @Default(true) bool isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] as num? ?? 0).toDouble(),
      imageUrl: d['imageUrl'] ?? '',
      category: d['category'] ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      options: d['options'] != null
          ? List<Map<String, dynamic>>.from(
              d['options'].map((e) => Map<String, dynamic>.from(e)),
            )
          : [],
      addons: d['addons'] != null
          ? List<Map<String, dynamic>>.from(
              d['addons'].map((e) => Map<String, dynamic>.from(e)),
            )
          : [],
      isVeg: d['isVeg'] ?? true,
      isAvailable: d['isAvailable'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Item.fromMap(String id, Map<String, dynamic> d) => Item(
    id: id,
    vendorId: d['vendorId'] ?? '',
    name: d['name'] ?? '',
    description: d['description'] ?? '',
    price: (d['price'] as num? ?? 0).toDouble(),
    imageUrl: d['imageUrl'] ?? '',
    category: d['category'] ?? '',
    tags: List<String>.from(d['tags'] ?? []),
    options: d['options'] != null
        ? List<Map<String, dynamic>>.from(
            d['options'].map((e) => Map<String, dynamic>.from(e)),
          )
        : [],
    addons: d['addons'] != null
        ? List<Map<String, dynamic>>.from(
            d['addons'].map((e) => Map<String, dynamic>.from(e)),
          )
        : [],
    isVeg: d['isVeg'] ?? true,
    isAvailable: d['isAvailable'] ?? true,
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
  );
}

extension ItemExtensions on Item {
  bool get hasCustomizations {
    return _isEntryAvailable(options) || _isEntryAvailable(addons);
  }

  bool _isEntryAvailable(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return false;
    for (final i in items) {
      final val = i['isAvailable'] ?? i['availability'] ?? i['available'];
      if (val == null) return true;
      if (val is bool && val) return true;
      if (val is String &&
          (val.toLowerCase() == 'true' ||
              val.toLowerCase() == 'available' ||
              val == '1')) {
        return true;
      }
      if (val is num && val == 1) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> get availableOptions =>
      options.where((o) => _isItemAvailable(o)).toList();

  List<Map<String, dynamic>> get availableAddons =>
      addons.where((a) => _isItemAvailable(a)).toList();

  bool _isItemAvailable(Map<String, dynamic> data) {
    final val =
        data['isAvailable'] ?? data['availability'] ?? data['available'];
    if (val == null) return true;
    if (val is bool) return val;
    if (val is String) {
      final s = val.toLowerCase();
      return s == 'true' || s == 'available' || s == 'yes' || s == '1';
    }
    if (val is num) return val == 1;
    return false;
  }
}
