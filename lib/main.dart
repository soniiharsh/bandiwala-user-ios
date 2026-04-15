import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/splash_page.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/deep_link_service.dart';
import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  if (!kDebugMode) {
    try {
      print('DEBUG: Activating Firebase App Check');
      await FirebaseAppCheck.instance.activate(
        providerAndroid: AndroidPlayIntegrityProvider(),
        providerApple: AppleDeviceCheckProvider(),
      );
    } catch (_) {}
  }

  NotificationService().initialize();
  AnalyticsService.logAppOpen();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      _ => MediaQuery.platformBrightnessOf(context),
    };

    // Init deep links once — foreground links work immediately,
    // cold-start links wait until splash signals it's done.
    DeepLinkService.init(navigatorKey);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiStyle(brightness),
      child: MaterialApp(
        title: 'BandiWala',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [AnalyticsService.observer],
        home: const SplashPage(),
      ),
    );
  }
}
