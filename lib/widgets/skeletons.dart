import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── Shared shimmer wrapper ───────────────────────────────────────────────────

class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade100,
      child: child,
    );
  }
}

// ─── Generic box ─────────────────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Circle ───────────────────────────────────────────────────────────────────

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Category carousel skeleton ──────────────────────────────────────────────

class CategoryCarouselSkeleton extends StatelessWidget {
  const CategoryCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: 7,
          itemBuilder: (_, __) => Container(
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonCircle(size: 64),
                const SizedBox(height: 7),
                SkeletonBox(height: 10, width: 48, radius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Promotional banner skeleton ──────────────────────────────────────────────

class PromotionalBannerSkeleton extends StatelessWidget {
  const PromotionalBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * (356 / 390);
    final cardHeight = cardWidth * (128 / 356);
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Recommended vendors strip skeleton ──────────────────────────────────────

class RecommendedVendorsSkeleton extends StatelessWidget {
  const RecommendedVendorsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: SizedBox(
        height: 215,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            width: 175,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 115,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 12, width: 120),
                      const SizedBox(height: 6),
                      SkeletonBox(height: 10, width: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vendor card (list) skeleton ──────────────────────────────────────────────

class VendorCardSkeleton extends StatelessWidget {
  const VendorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 160),
                  const SizedBox(height: 8),
                  SkeletonBox(height: 11, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vendors list skeleton ────────────────────────────────────────────────────

class VendorsListSkeleton extends StatelessWidget {
  const VendorsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: VendorCardSkeleton(),
        ),
      ),
    );
  }
}

// ─── Vendor items page skeleton ───────────────────────────────────────────────

class VendorItemsSkeleton extends StatelessWidget {
  const VendorItemsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 220, color: color),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 20, width: 200),
                const SizedBox(height: 8),
                SkeletonBox(height: 13, width: 140),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    4,
                    (_) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: SkeletonBox(height: 32, width: 72, radius: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        SkeletonBox(height: 80, width: 80, radius: 10),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(
                                  height: 14, width: double.infinity),
                              const SizedBox(height: 6),
                              SkeletonBox(height: 11, width: 120),
                              const SizedBox(height: 10),
                              SkeletonBox(height: 13, width: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order card skeleton ──────────────────────────────────────────────────────

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(height: 36, width: 36, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 13, width: 160),
                      const SizedBox(height: 5),
                      SkeletonBox(height: 11, width: 100),
                    ],
                  ),
                ),
                SkeletonBox(height: 28, width: 80, radius: 20),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonBox(height: 11, width: double.infinity),
            const SizedBox(height: 6),
            SkeletonBox(height: 11, width: 200),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(height: 13, width: 80),
                SkeletonBox(height: 13, width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Orders list skeleton ─────────────────────────────────────────────────────

class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const OrderCardSkeleton(),
    );
  }
}

// ─── Coupons page skeleton ────────────────────────────────────────────────────

class CouponsListSkeleton extends StatelessWidget {
  const CouponsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(height: 36, width: 36, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          SkeletonBox(height: 14, width: double.infinity)),
                  const SizedBox(width: 12),
                  SkeletonBox(height: 28, width: 70, radius: 6),
                ],
              ),
              const SizedBox(height: 10),
              SkeletonBox(height: 11, width: 200),
              const SizedBox(height: 6),
              SkeletonBox(height: 11, width: 140),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile page skeleton ────────────────────────────────────────────────────

class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SkeletonBox(height: 22, width: 180),
            const SizedBox(height: 6),
            SkeletonBox(height: 14, width: 120),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SkeletonBox(height: 40, width: 40, radius: 10),
                    const SizedBox(width: 14),
                    Expanded(
                        child:
                            SkeletonBox(height: 14, width: double.infinity)),
                    const SizedBox(width: 12),
                    SkeletonBox(height: 14, width: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wishlist page skeleton ───────────────────────────────────────────────────

class WishlistPageSkeleton extends StatelessWidget {
  const WishlistPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 11, width: 90),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 11, width: 60),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Saved addresses page skeleton ───────────────────────────────────────────

class SavedAddressesSkeleton extends StatelessWidget {
  const SavedAddressesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SkeletonBox(height: 40, width: 40, radius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 100),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 11, width: double.infinity),
                    const SizedBox(height: 4),
                    SkeletonBox(height: 11, width: 160),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart / auth-gate skeleton ────────────────────────────────────────────────

class CartLoadingSkeleton extends StatelessWidget {
  const CartLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Scaffold(
      body: SkeletonShimmer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 16),
              SkeletonBox(height: 22, width: 120),
              const SizedBox(height: 20),
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav page (app boot) skeleton ─────────────────────────────────────────────

class AppBootSkeleton extends StatelessWidget {
  const AppBootSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: Color(0xFFFFC107),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}
