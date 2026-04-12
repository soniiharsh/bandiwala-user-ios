import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single source of truth for all environment / config variables.
///
/// Usage:  `AppEnv.googleMapsApiKey`
///
/// Must call `await dotenv.load()` in `main()` before using any value.
abstract final class AppEnv {
  // ── API Keys ────────────────────────────────────────────────────────────────
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get razorpayKey =>
      dotenv.env['RAZORPAY_KEY'] ?? '';

  // ── Store URLs ──────────────────────────────────────────────────────────────
  static String get playStoreUrl =>
      dotenv.env['PLAY_STORE_URL'] ?? '';

  static String get appStoreUrl =>
      dotenv.env['APP_STORE_URL'] ?? '';

  /// Returns the correct store URL based on the current platform.
  static String get storeUrl =>
      Platform.isIOS ? appStoreUrl : playStoreUrl;

  // ── Support & Contact ──────────────────────────────────────────────────────
  static String get supportPhone =>
      dotenv.env['SUPPORT_PHONE'] ?? '';

  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? '';

  static String get supportHours =>
      dotenv.env['SUPPORT_HOURS'] ?? '';

  // ── Business Emails ────────────────────────────────────────────────────────
  static String get generalEmail =>
      dotenv.env['GENERAL_EMAIL'] ?? '';

  static String get privacyEmail =>
      dotenv.env['PRIVACY_EMAIL'] ?? '';

  static String get complianceEmail =>
      dotenv.env['COMPLIANCE_EMAIL'] ?? '';

  static String get customerEmail =>
      dotenv.env['CUSTOMER_EMAIL'] ?? '';

  /// Formatted support contact block (for policy pages).
  static String get supportContactBlock =>
      'Email: $supportEmail\nPhone: $supportPhone\nSupport Hours: $supportHours';

  /// Short contact block (for cancellation page).
  static String get supportContactShort =>
      'Email: $supportEmail\nPhone: $supportPhone';

  /// Full contact block for terms page.
  static String get termsContactBlock =>
      'General Inquiries: $generalEmail\n'
      'Customer Support: $supportEmail\n'
      'Privacy Concerns: $privacyEmail\n'
      'Compliance Issues: $complianceEmail';
}
