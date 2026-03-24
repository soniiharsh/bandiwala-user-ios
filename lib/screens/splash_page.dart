import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/active_address_provider.dart';
import 'nav_page.dart';
import 'login_page.dart';
import '../core/theme/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Hydrate the active address index from SharedPreferences once at startup.
    // This is fire-and-forget — the provider will rebuild when done.
    ref.read(activeAddressProvider.notifier).loadFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(userProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (_, __) => const LoginPage(),
      data: (user) => user != null ? const NavPage() : const LoginPage(),
    );
  }
}
