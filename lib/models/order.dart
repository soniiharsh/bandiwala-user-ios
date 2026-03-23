import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class OrderDeliveryAddress {
  final String address;
  final String geolocation;
  final double latitude;
  final double longitude;

  const OrderDeliveryAddress({
    required this.address,
    required this.geolocation,
    required this.latitude,
    required this.longitude,
  });

  factory OrderDeliveryAddress.fromSavedAddress(SavedAddress s) =>
      OrderDeliveryAddress(
        address: s.address ?? '',
        geolocation: s.geolocation,
        latitude: s.latitude,
        longitude: s.longitude,
      );

  factory OrderDeliveryAddress.fromMap(Map<String, dynamic> m) =>
      OrderDeliveryAddress(
        address: m['address'] ?? '',
        geolocation: m['geolocation'] ?? '',
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
    'address': address,
    'geolocation': geolocation,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class OrderItem {
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    name: m['name'] ?? '',
    price: (m['price'] as num? ?? 0).toDouble(),
    quantity: (m['quantity'] as num? ?? 1).toInt(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };
}

class VendorOrder {
  final String vendorName;
  final Map<String, OrderItem> items;
  final String status;
  final DateTime? statusUpdatedAt;

  const VendorOrder({
    required this.vendorName,
    required this.items,
    this.status = 'pending',
    this.statusUpdatedAt,
  });

  factory VendorOrder.fromMap(Map<String, dynamic> m) {
    final rawItems = m['items'];
    final Map<String, OrderItem> items = {};

    if (rawItems is Map) {
      rawItems.forEach((key, value) {
        items[key.toString()] = OrderItem.fromMap(
          Map<String, dynamic>.from(value as Map),
        );
      });
    } else if (rawItems is List) {
      // legacy list format — use itemId or index as key
      for (int i = 0; i < rawItems.length; i++) {
        final item = Map<String, dynamic>.from(rawItems[i] as Map);
        final key = (item['itemId'] ?? item['id'] ?? i.toString()).toString();
        items[key] = OrderItem.fromMap(item);
      }
    }

    return VendorOrder(
      vendorName: m['vendorName'] ?? '',
      items: items,
      status: m['status'] ?? 'pending',
      statusUpdatedAt: (m['statusUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'vendorName': vendorName,
    'items': items.map((k, v) => MapEntry(k, v.toMap())),
    'status': status,
    'statusUpdatedAt': statusUpdatedAt != null
        ? Timestamp.fromDate(statusUpdatedAt!)
        : FieldValue.serverTimestamp(),
  };
}

class AppOrder {
  final String id;
  final String userId;
  final String customerPhone;
  final OrderDeliveryAddress deliveryAddress;
  final Map<String, VendorOrder> itemsByVendor;
  final List<String> vendorIds;
  final String paymentMethod;
  final String paymentId;
  final double deliveryFee;
  final double platformFee;
  final double foodTax;
  final double deliveryTax;
  final bool platformTax;
  final bool couponApplied;
  final String couponCode;
  final String couponType;
  final double couponDiscount;
  final double couponMaxDiscountableAmount;
  final double grandTotal;
  final String status;
  final DateTime? statusUpdatedAt;
  final DateTime? createdAt;

  const AppOrder({
    required this.id,
    required this.userId,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.itemsByVendor,
    required this.vendorIds,
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
  });

  // Convenience getter for items total (base price before fees/taxes)
  double get itemsTotal => itemsByVendor.values.fold(0.0, (acc, vo) {
    return acc + vo.items.values.fold(0.0, (s, i) => s + i.price * i.quantity);
  });

  AppOrder copyWith({
    String? paymentId,
    String? paymentMethod,
    String? status,
  }) => AppOrder(
    id: id,
    userId: userId,
    customerPhone: customerPhone,
    deliveryAddress: deliveryAddress,
    itemsByVendor: itemsByVendor,
    vendorIds: vendorIds,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentId: paymentId ?? this.paymentId,
    deliveryFee: deliveryFee,
    platformFee: platformFee,
    foodTax: foodTax,
    deliveryTax: deliveryTax,
    platformTax: platformTax,
    couponApplied: couponApplied,
    couponCode: couponCode,
    couponType: couponType,
    couponDiscount: couponDiscount,
    couponMaxDiscountableAmount: couponMaxDiscountableAmount,
    grandTotal: grandTotal,
    status: status ?? this.status,
    statusUpdatedAt: statusUpdatedAt,
    createdAt: createdAt,
  );

  factory AppOrder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // itemsByVendor: support map (new) and array (legacy)
    final Map<String, VendorOrder> itemsByVendor = {};
    final ibv = d['itemsByVendor'];
    if (ibv is Map) {
      ibv.forEach((key, value) {
        itemsByVendor[key.toString()] = VendorOrder.fromMap(
          Map<String, dynamic>.from(value as Map),
        );
      });
    } else if (ibv is List) {
      for (final entry in ibv) {
        final m = Map<String, dynamic>.from(entry as Map);
        final vendorId = (m['vendorId'] ?? '').toString();
        if (vendorId.isNotEmpty) {
          itemsByVendor[vendorId] = VendorOrder.fromMap(m);
        }
      }
    }

    return AppOrder(
      id: doc.id,
      userId: d['userId'] ?? '',
      customerPhone: d['customerPhone'] ?? '',
      deliveryAddress: OrderDeliveryAddress.fromMap(
        Map<String, dynamic>.from(
          d['deliveryAddress'] ?? d['deliveryLocation'] ?? {},
        ),
      ),
      itemsByVendor: itemsByVendor,
      vendorIds: List<String>.from(d['vendorIds'] ?? []),
      paymentMethod: d['paymentMethod'] ?? '',
      paymentId: d['paymentId'] ?? '',
      deliveryFee: (d['deliveryFee'] ?? d['deliveryCharge'] as num? ?? 0)
          .toDouble(),
      platformFee: (d['platformFee'] as num? ?? 0).toDouble(),
      foodTax: (d['foodTax'] ?? d['foodTaxAmount'] as num? ?? 0).toDouble(),
      deliveryTax: (d['deliveryTax'] as num? ?? 0).toDouble(),
      platformTax: d['platformTax'] ?? false,
      couponApplied: d['couponApplied'] ?? false,
      couponCode: d['couponCode'] ?? '',
      couponType: d['couponType'] ?? '',
      couponDiscount: (d['couponDiscount'] as num? ?? 0).toDouble(),
      couponMaxDiscountableAmount:
          (d['couponMaxDiscountableAmount'] as num? ?? 0).toDouble(),
      grandTotal: (d['grandTotal'] as num? ?? 0).toDouble(),
      status: d['status'] ?? 'unknown',
      statusUpdatedAt: (d['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp? ?? d['timestamp'] as Timestamp?)
          ?.toDate(),
    );
  }
}
