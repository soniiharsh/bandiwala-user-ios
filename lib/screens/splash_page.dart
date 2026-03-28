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
  ConsumerState<SplashPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashPage> {
  late VideoPlayerController _controller;
  bool _videoFinished = false;
  bool _isNavigating = false;
  bool _minDurationElapsed = false;

  @override
  void initState() {
    super.initState();
    ref.read(activeAddressProvider.notifier).loadFromPrefs();
    
    _controller = VideoPlayerController.asset('assets/videos/splash.mov')
      ..initialize().then((_) {
        // Small delay to ensure initialization is fully settled
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
            _controller.play();
          }
        });
      }).catchError((e) {
        debugPrint('Splash video error: $e');
        setState(() => _videoFinished = true);
        _maybeNavigate();
      });

    _controller.addListener(() {
      if (!mounted) return;
      final val = _controller.value;
      if (val.position >= val.duration && val.duration > Duration.zero && !_videoFinished) {
        setState(() => _videoFinished = true);
        _maybeNavigate();
      }
    });

    // Substantially increased duration: 6 seconds total
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) {
        setState(() => _minDurationElapsed = true);
        _maybeNavigate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (_isNavigating) return;
    
    final authAsync = ref.read(userProvider);
    
    // Requirements:
    // 1. Video must be finished (or error)
    // 2. Minimum 6s duration must have passed
    // 3. User data must be synced
    if (_videoFinished && _minDurationElapsed && authAsync.hasValue) {
      _isNavigating = true;
      _navigateToNext(authAsync.valueOrNull);
    }
  }

  void _navigateToNext(AppUser? user) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => user != null ? const NavPage() : const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userProvider, (previous, next) {
      if (next.hasValue || next.hasError) {
        _maybeNavigate();
      }
    });
    final isInitialized = _controller.value.isInitialized;

    return Scaffold(
      // Initial screen is white, becomes yellow once video starts, and STAYS yellow after video ends
      backgroundColor: isInitialized ? AppColors.primary : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Show Video once initialized
          if (isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          // Show static image once video is finished (Phase 4)
          if (_videoFinished)
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash.png',
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
