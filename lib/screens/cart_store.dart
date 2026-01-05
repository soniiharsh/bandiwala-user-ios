// cart_store.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

/// GLOBAL INSTANCE – use this everywhere
final CartStore cartStore = CartStore();

class CartStore extends ChangeNotifier {
  // vendorId -> vendor cart
  final Map<String, VendorCart> _cartByVendor = {};

  static const _prefsKey = 'bandiwala_cart_v1';

  Map<String, VendorCart> get cartByVendor => _cartByVendor;

  bool get hasItems =>
      _cartByVendor.values.any((v) => v.items.isNotEmpty);

  int get totalItemCount {
    int count = 0;
    for (final v in _cartByVendor.values) {
      for (final item in v.items) {
        count += item.quantity;
      }
    }
    return count;
  }

  double vendorTotal(String vendorId) {
    final vendor = _cartByVendor[vendorId];
    if (vendor == null) return 0;
    return vendor.items.fold(
      0,
          (sum, item) => sum + item.price * item.quantity,
    );
  }

  double get grandTotal {
    double total = 0;
    _cartByVendor.forEach((key, vendor) {
      total += vendor.items.fold(
        0,
            (sum, item) => sum + item.price * item.quantity,
      );
    });
    return total;
  }

  // ---------- PERSISTENCE ----------

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) return;

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    _cartByVendor.clear();

    decoded.forEach((vendorId, vendorJson) {
      _cartByVendor[vendorId] =
          VendorCart.fromJson(vendorJson as Map<String, dynamic>);
    });

    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _cartByVendor.forEach((vendorId, vendorCart) {
      map[vendorId] = vendorCart.toJson();
    });
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  // ---------- MUTATIONS ----------

  void addItem({
    required String vendorId,
    required String vendorName,
    required String itemId,
    required String itemName,
    required double price,
  }) {
    final vendor = _cartByVendor.putIfAbsent(
      vendorId,
          () => VendorCart(vendorName: vendorName, items: []),
    );

    final index = vendor.items.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      vendor.items.add(
        CartItem(
          id: itemId,
          name: itemName,
          price: price,
          quantity: 1,
        ),
      );
    } else {
      final existing = vendor.items[index];
      vendor.items[index] =
          existing.copyWith(quantity: existing.quantity + 1);
    }

    _saveToDisk();
    notifyListeners();
  }

  void updateQuantity({
    required String vendorId,
    required String itemId,
    required int delta,
  }) {
    final vendor = _cartByVendor[vendorId];
    if (vendor == null) return;

    final index = vendor.items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = vendor.items[index];
    final newQty = (item.quantity + delta).clamp(0, 99);
    if (newQty == 0) {
      vendor.items.removeAt(index);
    } else {
      vendor.items[index] = item.copyWith(quantity: newQty);
    }

    if (vendor.items.isEmpty) {
      _cartByVendor.remove(vendorId);
    }

    _saveToDisk();
    notifyListeners();
  }

  Future<void> clear() async {
    _cartByVendor.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}

class VendorCart {
  final String vendorName;
  final List<CartItem> items;

  VendorCart({
    required this.vendorName,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'vendorName': vendorName,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory VendorCart.fromJson(Map<String, dynamic> json) => VendorCart(
    vendorName: json['vendorName'] as String,
    items: (json['items'] as List<dynamic>)
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int,
  );
}
