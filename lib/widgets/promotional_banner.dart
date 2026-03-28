import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../models/promotion.dart';
import '../providers/promotions_provider.dart';
import '../core/theme/theme.dart';
import 'skeletons.dart';

const kBandiwalaYellow = AppColors.primary;

// ─── PromotionalBanner ────────────────────────────────────────────────────────

class PromotionalBanner extends ConsumerStatefulWidget {
  const PromotionalBanner({super.key});

  @override
  ConsumerState<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends ConsumerState<PromotionalBanner>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % count;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final promotionsAsync = ref.watch(promotionsProvider);

    return promotionsAsync.when(
      loading: () => const PromotionalBannerSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (promotions) {
        if (promotions.isEmpty) return const SizedBox.shrink();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startAutoScroll(promotions.length),
        );
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = screenWidth * (356 / 390);
        final cardHeight = cardWidth * (128 / 356);
        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: promotions.length,
                itemBuilder: (_, i) =>
                    _PromotionalImageCard(promotion: promotions[i]),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promotions.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? kBandiwalaYellow
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── _PromotionalImageCard ────────────────────────────────────────────────────

class _PromotionalImageCard extends StatelessWidget {
  final Promotion promotion;

  const _PromotionalImageCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: promotion.imageUrl.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: promotion.imageUrl.trim(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 46,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 46,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
      ),
    );
  }
}
