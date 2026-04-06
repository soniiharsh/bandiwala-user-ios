import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../providers/user_provider.dart';
import '../providers/active_address_provider.dart';
import '../models/app_user.dart';
import 'nav_page.dart';
import 'login_page.dart';
import '../core/theme/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    ref.read(activeAddressProvider.notifier).loadFromPrefs();

    _controller = VideoPlayerController.asset('assets/videos/splash.mp4');

    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      await _controller.play();

      // wait for video to finish
      await Future.delayed(_controller.value.duration);

      // wait for auth state
      final authAsync = ref.read(userProvider);

      if (!mounted) return;

      _navigate(authAsync.valueOrNull);
    } catch (e) {
      debugPrint("Splash error: $e");
      _navigate(null);
    }
  }

  void _navigate(AppUser? user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user != null ? const NavPage() : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: initialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
