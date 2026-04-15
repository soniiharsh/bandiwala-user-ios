import 'package:bandiwala_user/core/db_collections.dart';
import 'package:bandiwala_user/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/user_provider.dart';
import '../providers/active_address_provider.dart';
import '../models/app_user.dart';
import 'nav_page.dart';
import 'login_page.dart';
import 'update_required_page.dart';
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

      // Run video wait, auth resolution, and version check all in parallel.
      // Auth uses .future so we wait for the actual resolved value, not
      // AsyncLoading (which would give us a false null → LoginPage redirect).
      final results = await Future.wait([
        Future.delayed(_controller.value.duration),
        ref.read(userProvider.future),
        _checkVersion(),
      ]);

      if (!mounted) return;

      final appUser = results[1] as AppUser?;
      final versionResult = results[2] as _VersionResult;

      if (versionResult.isOutdated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UpdateRequiredPage(
              currentVersion: versionResult.currentVersion,
              minimumVersion: versionResult.minimumVersion,
            ),
          ),
        );
        return;
      }

      _navigate(appUser);
    } catch (e) {
      debugPrint('Splash error: $e');
      _navigate(null);
    }
  }

  /// Checks Firestore for the minimum required version.
  /// Checks Firestore for the minimum required version.
  /// Only bypasses the check on network/unavailability errors.
  /// Any other failure (bad data, parse error) is treated as outdated.
  Future<_VersionResult> _checkVersion() async {
    late final String current;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      current = packageInfo.version;
    } catch (_) {
      // Can't read own version — treat as outdated to be safe.
      return const _VersionResult(
        currentVersion: '',
        minimumVersion: '',
        isOutdated: true,
      );
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection(DbCollections.latestVersion)
          .limit(1)
          .get();
      print("Document count: ${snap.docs.length}");

      if (snap.docs.isEmpty) {
        // No version document configured — block the app until one is set.
        return _VersionResult(
          currentVersion: current,
          minimumVersion: 'unknown',
          isOutdated: true,
        );
      }
      final data = snap.docs.first.data();

      final minimum = data['minimum-version'];
      if (minimum is! String || minimum.isEmpty) {
        // Malformed version field — treat as outdated.
        return _VersionResult(
          currentVersion: current,
          minimumVersion: 'unknown',
          isOutdated: true,
        );
      }

      return _VersionResult(
        currentVersion: current,
        minimumVersion: minimum,
        isOutdated: _isOlderVersion(current, minimum),
      );
    } on FirebaseException catch (e) {
      // Network/unavailable — give benefit of the doubt.
      debugPrint(
        'Version check Firestore error: ${e.code} ${e.message} ------------------------------------------------------------------------------------',
      );
      return _VersionResult.upToDate(current);
    } catch (e) {
      // Unexpected error — treat as outdated.
      debugPrint(
        'Version check unexpected error: $e ------------------------------------------------------------------------------------',
      );
      return _VersionResult(
        currentVersion: current,
        minimumVersion: '',
        isOutdated: true,
      );
    }
  }

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

  void _navigate(AppUser? user) {
    DeepLinkService.onSplashComplete();
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

class _VersionResult {
  final String currentVersion;
  final String minimumVersion;
  final bool isOutdated;

  const _VersionResult({
    required this.currentVersion,
    required this.minimumVersion,
    required this.isOutdated,
  });

  factory _VersionResult.upToDate(String current) => _VersionResult(
    currentVersion: current,
    minimumVersion: '',
    isOutdated: false,
  );
}
