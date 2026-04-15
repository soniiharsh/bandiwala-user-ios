import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/vendor_items_page.dart';
import '../core/navigation/app_page_route.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static bool _initialized = false;

  // Holds the cold-start URI until splash signals ready
  static Uri? _pendingUri;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    // Capture cold-start link but don't navigate yet — splash isn't done
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _pendingUri = initialUri;
    }

    // Foreground links — navigate immediately, splash is already done
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, navigatorKey);
    });
  }

  /// Call this from SplashPage right before it calls Navigator.pushReplacement
  static void onSplashComplete() {
    if (_pendingUri != null && _navigatorKey != null) {
      // Small delay to let the new route settle after pushReplacement
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleUri(_pendingUri!, _navigatorKey!);
        _pendingUri = null;
      });
    }
  }

  static void _handleUri(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    final screen = uri.queryParameters['screen'];
    final id = uri.queryParameters['id'];
    final name = uri.queryParameters['name'];

    if (screen == 'vendor' && id != null && name != null) {
      navigatorKey.currentState?.push(
        AppPageRoute(
          builder: (_) => VendorItemsPage(vendorId: id, vendorName: name),
        ),
      );
    }
  }
}
