// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderDeliveryAddressImpl _$$OrderDeliveryAddressImplFromJson(
  Map<String, dynamic> json,
) => _$OrderDeliveryAddressImpl(
  address: json['address'] as String,
  geolocation: json['geolocation'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$$OrderDeliveryAddressImplToJson(
  _$OrderDeliveryAddressImpl instance,
) => <String, dynamic>{
  'address': instance.address,
  'geolocation': instance.geolocation,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      selectedOption: json['selectedOption'] as Map<String, dynamic>? ?? null,
      selectedAddons:
          (json['selectedAddons'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price': instance.price,
      'quantity': instance.quantity,
      'selectedOption': instance.selectedOption,
      'selectedAddons': instance.selectedAddons,
    };

_$VendorOrderImpl _$$VendorOrderImplFromJson(Map<String, dynamic> json) =>
    _$VendorOrderImpl(
      vendorName: json['vendorName'] as String,
      items: (json['items'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, OrderItem.fromJson(e as Map<String, dynamic>)),
      ),
      status:
          $enumDecodeNullable(_$VendorOrderStatusEnumMap, json['status']) ??
          VendorOrderStatus.pending,
      statusUpdatedAt: json['statusUpdatedAt'] == null
          ? null
          : DateTime.parse(json['statusUpdatedAt'] as String),
    );

Map<String, dynamic> _$$VendorOrderImplToJson(_$VendorOrderImpl instance) =>
    <String, dynamic>{
      'vendorName': instance.vendorName,
      'items': instance.items,
      'status': _$VendorOrderStatusEnumMap[instance.status]!,
      'statusUpdatedAt': instance.statusUpdatedAt?.toIso8601String(),
    };

const _$VendorOrderStatusEnumMap = {
  VendorOrderStatus.pending: 'pending',
  VendorOrderStatus.accepted: 'accepted',
  VendorOrderStatus.rejected: 'rejected',
};

_$AppOrderImpl _$$AppOrderImplFromJson(Map<String, dynamic> json) =>
    _$AppOrderImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      customerPhone: json['customerPhone'] as String,
      deliveryAddress: OrderDeliveryAddress.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      itemsByVendor: (json['itemsByVendor'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, VendorOrder.fromJson(e as Map<String, dynamic>)),
      ),
      vendorIds: (json['vendorIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      paymentMethod: json['paymentMethod'] as String,
      paymentId: json['paymentId'] as String,
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      foodTax: (json['foodTax'] as num).toDouble(),
      deliveryTax: (json['deliveryTax'] as num).toDouble(),
      platformTax: json['platformTax'] as bool,
      couponApplied: json['couponApplied'] as bool? ?? false,
      couponCode: json['couponCode'] as String? ?? '',
      couponType: json['couponType'] as String? ?? '',
      couponDiscount: (json['couponDiscount'] as num?)?.toDouble() ?? 0,
      couponMaxDiscountableAmount:
          (json['couponMaxDiscountableAmount'] as num?)?.toDouble() ?? 0,
      couponVendorId: json['couponVendorId'] as String? ?? '',
      grandTotal: (json['grandTotal'] as num).toDouble(),
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      statusUpdatedAt: json['statusUpdatedAt'] == null
          ? null
          : DateTime.parse(json['statusUpdatedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      assignedTo: json['assignedTo'] as String? ?? null,
      deliveryAgentLocation:
          (json['deliveryAgentLocation'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          null,
    );

Map<String, dynamic> _$$AppOrderImplToJson(_$AppOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'customerPhone': instance.customerPhone,
      'deliveryAddress': instance.deliveryAddress,
      'itemsByVendor': instance.itemsByVendor,
      'vendorIds': instance.vendorIds,
      'paymentMethod': instance.paymentMethod,
      'paymentId': instance.paymentId,
      'deliveryFee': instance.deliveryFee,
      'platformFee': instance.platformFee,
      'foodTax': instance.foodTax,
      'deliveryTax': instance.deliveryTax,
      'platformTax': instance.platformTax,
      'couponApplied': instance.couponApplied,
      'couponCode': instance.couponCode,
      'couponType': instance.couponType,
      'couponDiscount': instance.couponDiscount,
      'couponMaxDiscountableAmount': instance.couponMaxDiscountableAmount,
      'couponVendorId': instance.couponVendorId,
      'grandTotal': instance.grandTotal,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'statusUpdatedAt': instance.statusUpdatedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'assignedTo': instance.assignedTo,
      'deliveryAgentLocation': instance.deliveryAgentLocation,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.orderCreated: 'orderCreated',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.outForDelivery: 'outForDelivery',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};
