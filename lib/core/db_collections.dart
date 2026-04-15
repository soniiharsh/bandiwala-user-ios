/// Single source of truth for all Firestore collection names.
/// Swap the values here to switch between test and production databases.
abstract class DbCollections {
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String items = 'items';
  static const String orders = 'orders1';
  static const String foodCategories = 'food_categories';
  static const String promotions = 'promotions';
  static const String coupons = 'coupons';
  static const String serviceZones = 'serviceLocations';
  static const String pricingConfig = 'pricing_config';
  static const String announcements = 'announcements';
  static const String logs = 'logs';
  static const String admins = 'admins';
  static const String statusUpdates = 'status_updates';
  static const String latestVersion = 'latest_version';
  static const String couponRedemptions = 'coupon_redemptions';
  static const String hexagons = 'hexagons';
}
