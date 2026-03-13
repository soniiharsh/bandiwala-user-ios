import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_options.dart';
import 'screens/cart_store.dart';
import 'screens/splash_screen.dart';
import 'screens/update_required_screen.dart';
import 'services/notification_service.dart';
import 'services/version_checker.dart';
import 'services/analytics_service.dart';
import 'package:flutter/foundation.dart';

String APP_VERSION = '1.0.0'; // Fallback version

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Set white background for app startup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optimize Firestore: enable local persistence and unlimited cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );

    if (kDebugMode) {
      print('🧪 App Check running with DEBUG provider');
      print('Register the debug token in Firebase Console → App Check');
    } else {
      print('🔒 App Check running with Play Integrity');
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('❌ App Check initialization failed');
      print(e);
      print(stack);
    }
  }

  await cartStore.loadFromDisk();

  // Initialize notifications and subscribe to admin topic
  await NotificationService().initialize();

  // Get app version from pubspec.yaml
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    APP_VERSION = packageInfo.version;
    if (kDebugMode) {
      print('📱 App Version: $APP_VERSION (Build ${packageInfo.buildNumber})');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Failed to get app version: $e');
    }
  }

  await AnalyticsService.logAppOpen();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Bandiwala',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107)),
          scaffoldBackgroundColor: Colors.white,
        ),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AnalyticsService.observer],
        home: const VersionCheckWrapper(),
      ),
    );
  }
}

class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _isChecking = true;
  bool _updateRequired = false;
  String _minimumVersion = '';

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final result = await VersionChecker.checkAppVersion(APP_VERSION);

      if (mounted) {
        setState(() {
          _updateRequired = result.updateRequired;
          _minimumVersion = result.minimumVersion;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Version check error: $e');
      }
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
          ),
        ),
      );
    }

    if (_updateRequired) {
      return UpdateRequiredScreen(
        currentVersion: APP_VERSION,
        minimumVersion: _minimumVersion,
      );
    }

    return const SplashScreen();
  }
}
