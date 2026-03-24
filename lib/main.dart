import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/splash_page.dart';
import 'screens/update_required_page.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'core/theme/theme.dart';

String appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiStyle);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Disable reCAPTCHA / app verification in debug builds — must be set
  // before App Check activates so it isn't overridden.
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  // Disable offline persistence so failures are visible when there's no internet
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Skip App Check entirely in debug — it blocks phone auth even with
  // appVerificationDisabledForTesting set.
  if (!kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: AndroidPlayIntegrityProvider(),
        providerApple: AppleDeviceCheckProvider(),
      );
    } catch (_) {}
  }

  // Non-blocking — resolve in background
  PackageInfo.fromPlatform().then((info) => appVersion = info.version);

  // Fire and forget — no await
  NotificationService().initialize();
  AnalyticsService.logAppOpen();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiStyle,
      child: MaterialApp(
        title: 'Bandiwala',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AnalyticsService.observer],
        home: const VersionCheckWrapper(),
      ),
    );
  }
}

// ── Version check runs in background, doesn't block app startup ───────────────

class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _updateRequired = false;
  String _minimumVersion = '';

  @override
  void initState() {
    super.initState();
    _checkVersionInBackground();
  }

  Future<void> _checkVersionInBackground() async {
    try {
      // Resolve actual app version first
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final snap = await FirebaseFirestore.instance
          .collection('latest-version')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;

      final minVersion =
          snap.docs.first.data()['minimum-version'] as String? ?? '0.0.0';
      final isOutdated = _isOlderVersion(currentVersion, minVersion);

      if (mounted && isOutdated) {
        setState(() {
          _updateRequired = true;
          _minimumVersion = minVersion;
        });
      }
    } catch (_) {}
  }

  /// Returns true if [current] is older than [minimum].
  bool _isOlderVersion(String current, String minimum) {
    final c = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final m = minimum.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_updateRequired) {
      return UpdateRequiredPage(
        currentVersion: appVersion,
        minimumVersion: _minimumVersion,
      );
    }
    return const SplashPage();
  }
}
