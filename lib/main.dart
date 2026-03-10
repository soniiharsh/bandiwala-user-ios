import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/cart_store.dart';
import 'screens/splash_screen.dart';
import 'screens/update_required_screen.dart';
import 'services/notification_service.dart';
import 'services/version_checker.dart';

import 'package:flutter/foundation.dart';

const String APP_VERSION = '1.0.0'; // From pubspec.yaml

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

  if (!kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    } catch (e) {
      // Silently fail if App Check can't activate (non-critical for auth flow)
    }
  } else {
    print('⚠️ App Check SKIPPED in debug mode');
  }

  await cartStore.loadFromDisk();

  // Initialize notifications and subscribe to admin topic
  await NotificationService().initialize();

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
