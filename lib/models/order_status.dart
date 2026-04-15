enum OrderStatus {
  orderCreated,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled;

  /// Serialize to the Firestore string value
  String get value => switch (this) {
    OrderStatus.orderCreated => 'order_created',
    OrderStatus.confirmed => 'confirmed',
    OrderStatus.preparing => 'preparing',
    OrderStatus.ready => 'ready',
    OrderStatus.outForDelivery => 'out_for_delivery',
    OrderStatus.completed => 'completed',
    OrderStatus.cancelled => 'cancelled',
  };

  /// Deserialize from a Firestore string value
  static OrderStatus fromValue(String value) => switch (value) {
    'order_created' => OrderStatus.orderCreated,
    'confirmed' => OrderStatus.confirmed,
    'preparing' => OrderStatus.preparing,
    'ready' => OrderStatus.ready,
    'out_for_delivery' => OrderStatus.outForDelivery,
    'completed' => OrderStatus.completed,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.orderCreated,
  };
}

enum VendorOrderStatus {
  pending,
  accepted,
  rejected,
  readyForPickup;

  String get value => switch (this) {
    VendorOrderStatus.pending => 'pending',
    VendorOrderStatus.accepted => 'accepted',
    VendorOrderStatus.rejected => 'rejected',
    VendorOrderStatus.readyForPickup => 'ready_for_pickup',
  };

  static VendorOrderStatus fromValue(String value) => switch (value) {
    'accepted' => VendorOrderStatus.accepted,
    'rejected' => VendorOrderStatus.rejected,
    'ready_for_pickup' => VendorOrderStatus.readyForPickup,
    _ => VendorOrderStatus.pending,
  };
}
