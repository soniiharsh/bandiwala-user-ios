import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/splash_page.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      print('DEBUG: Activating Firebase App Check');
      await FirebaseAppCheck.instance.activate(
        providerAndroid: AndroidPlayIntegrityProvider(),
        providerApple: AppleDeviceCheckProvider(),
      );
    } catch (_) {}
  }

  // Fire and forget — no await
  NotificationService().initialize();
  AnalyticsService.logAppOpen();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      _ => MediaQuery.platformBrightnessOf(context),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiStyle(brightness),
      child: MaterialApp(
        title: 'Bandiwala',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AnalyticsService.observer],
        home: const SplashPage(),
      ),
    );
  }
}
