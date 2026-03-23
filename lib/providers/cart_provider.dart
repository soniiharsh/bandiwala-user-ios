import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    id: j['id'],
    name: j['name'],
    price: (j['price'] as num).toDouble(),
    quantity: j['quantity'] as int,
  );
}

class VendorCart {
  final String vendorName;
  final List<CartItem> items;

  const VendorCart({required this.vendorName, required this.items});

  VendorCart copyWith({List<CartItem>? items}) =>
      VendorCart(vendorName: vendorName, items: items ?? this.items);

  Map<String, dynamic> toJson() => {
    'vendorName': vendorName,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory VendorCart.fromJson(Map<String, dynamic> j) => VendorCart(
    vendorName: j['vendorName'],
    items: (j['items'] as List).map((e) => CartItem.fromJson(e)).toList(),
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class CartState {
  final Map<String, VendorCart> cartByVendor;

  const CartState({this.cartByVendor = const {}});

  bool get hasItems => cartByVendor.values.any((v) => v.items.isNotEmpty);

  int get totalItemCount => cartByVendor.values
      .expand((v) => v.items)
      .fold(0, (sum, i) => sum + i.quantity);

  double get grandTotal => cartByVendor.values
      .expand((v) => v.items)
      .fold(0.0, (sum, i) => sum + i.price * i.quantity);

  double vendorTotal(String vendorId) =>
      cartByVendor[vendorId]?.items.fold<double>(
        0.0,
        (sum, i) => sum + i.price * i.quantity,
      ) ??
      0.0;

  CartState copyWith(Map<String, VendorCart> cartByVendor) =>
      CartState(cartByVendor: cartByVendor);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  static const _prefsKey = 'bandiwala_cart_v2';

  CartNotifier() : super(const CartState()) {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = decoded.map(
        (k, v) => MapEntry(k, VendorCart.fromJson(v as Map<String, dynamic>)),
      );
      state = CartState(cartByVendor: map);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = state.cartByVendor.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  void addItem({
    required String vendorId,
    required String vendorName,
    required String itemId,
    required String itemName,
    required double price,
  }) {
    final current = Map<String, VendorCart>.from(state.cartByVendor);
    final vendor =
        current[vendorId] ?? VendorCart(vendorName: vendorName, items: []);
    final items = List<CartItem>.from(vendor.items);
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1) {
      items.add(
        CartItem(id: itemId, name: itemName, price: price, quantity: 1),
      );
    } else {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    }
    current[vendorId] = vendor.copyWith(items: items);
    state = CartState(cartByVendor: current);
    _persist();
    AnalyticsService.logAddToCart(
      itemId: itemId,
      itemName: itemName,
      itemCategory: 'food',
      price: price,
      quantity: 1,
    );
  }

  void updateQuantity({
    required String vendorId,
    required String itemId,
    required int delta,
  }) {
    final current = Map<String, VendorCart>.from(state.cartByVendor);
    final vendor = current[vendorId];
    if (vendor == null) return;
    final items = List<CartItem>.from(vendor.items);
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    final newQty = (items[idx].quantity + delta).clamp(0, 99);
    if (newQty == 0) {
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(quantity: newQty);
    }
    if (items.isEmpty) {
      current.remove(vendorId);
    } else {
      current[vendorId] = vendor.copyWith(items: items);
    }
    state = CartState(cartByVendor: current);
    _persist();
  }

  Future<void> clear() async {
    state = const CartState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (_) => CartNotifier(),
);
