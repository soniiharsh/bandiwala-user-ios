/// Single source of truth for all Firestore collection names.
/// Swap the values here to switch between test and production databases.
abstract class DbCollections {
  static const String users = 'users1';
  static const String vendors = 'vendors1';
  static const String items = 'items1';
  static const String orders = 'orders1';
  static const String foodCategories = 'food_categories1';
  static const String promotions = 'promotions1';
  static const String coupons = 'coupons1';
  static const String serviceZones = 'serviceLocations1';
  static const String pricingConfig = 'pricing_config';
  static const String announcements = 'announcements1';
  static const String logs = 'logs';
  static const String admins = 'admins';
  static const String statusUpdates = 'status_updates';
  static const String latestVersion = 'latest_version';
}
