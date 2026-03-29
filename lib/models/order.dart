import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/app_user.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class OrderDeliveryAddress with _$OrderDeliveryAddress {
  const OrderDeliveryAddress._();

  const factory OrderDeliveryAddress({
    required String address,
    required String geolocation,
    required double latitude,
    required double longitude,
  }) = _OrderDeliveryAddress;

  factory OrderDeliveryAddress.fromJson(Map<String, dynamic> json) =>
      _$OrderDeliveryAddressFromJson(json);

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
}

@freezed
class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String name,
    required double price,
    required int quantity,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    name: m['name'] ?? '',
    price: (m['price'] as num? ?? 0).toDouble(),
    quantity: (m['quantity'] as num? ?? 1).toInt(),
  );
}

@freezed
class VendorOrder with _$VendorOrder {
  const VendorOrder._();

  const factory VendorOrder({
    required String vendorName,
    required Map<String, OrderItem> items,
    @Default('pending') String status,
    DateTime? statusUpdatedAt,
  }) = _VendorOrder;

  factory VendorOrder.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderFromJson(json);

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
    'items': items.map((k, v) => MapEntry(k, v.toJson())),
    'status': status,
    'statusUpdatedAt': statusUpdatedAt != null
        ? Timestamp.fromDate(statusUpdatedAt!)
        : FieldValue.serverTimestamp(),
  };
}

@freezed
class AppOrder with _$AppOrder {
  const AppOrder._();

  const factory AppOrder({
    required String id,
    required String userId,
    required String customerPhone,
    required OrderDeliveryAddress deliveryAddress,
    required Map<String, VendorOrder> itemsByVendor,
    required List<String> vendorIds,
    required String paymentMethod,
    required String paymentId,
    required double deliveryFee,
    required double platformFee,
    required double foodTax,
    required double deliveryTax,
    required bool platformTax,
    @Default(false) bool couponApplied,
    @Default('') String couponCode,
    @Default('') String couponType,
    @Default(0) double couponDiscount,
    @Default(0) double couponMaxDiscountableAmount,

    /// "" = global coupon was applied; "<vendorId>" = vendor coupon
    @Default('') String couponVendorId,
    required double grandTotal,
    required String status,
    DateTime? statusUpdatedAt,
    DateTime? createdAt,
  }) = _AppOrder;

  factory AppOrder.fromJson(Map<String, dynamic> json) =>
      _$AppOrderFromJson(json);

  double get itemsTotal => itemsByVendor.values.fold(0.0, (acc, vo) {
    return acc + vo.items.values.fold(0.0, (s, i) => s + i.price * i.quantity);
  });

  factory AppOrder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

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
      couponVendorId: d['couponVendorId'] ?? '',
      grandTotal: (d['grandTotal'] as num? ?? 0).toDouble(),
      status: d['status'] ?? 'unknown',
      statusUpdatedAt: (d['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp? ?? d['timestamp'] as Timestamp?)
          ?.toDate(),
    );
  }
}
