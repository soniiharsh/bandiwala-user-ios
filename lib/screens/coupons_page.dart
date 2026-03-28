import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coupons_provider.dart';
import '../models/coupon.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';

const kBandiwalaYellow = AppColors.primary;

class CouponsPage extends ConsumerWidget {
  final double cartAmount;

  const CouponsPage({super.key, required this.cartAmount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(activeCouponsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Apply coupon',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: couponsAsync.when(
        loading: () => const CouponsListSkeleton(),
        error: (error, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (allCoupons) {
          if (allCoupons.isEmpty) return _buildEmptyState();

          final applicable = <Coupon>[];
          final notApplicable = <Coupon>[];

          for (final coupon in allCoupons) {
            if (cartAmount >= coupon.minAmount) {
              applicable.add(coupon);
            } else {
              notApplicable.add(coupon);
            }
          }

          final displayCoupons = [...applicable, ...notApplicable];

          return Column(
            children: [
              // Manual coupon entry
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: kBandiwalaYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter a valid coupon code',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: kBandiwalaYellow,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Coupons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: displayCoupons.length,
                  itemBuilder: (context, index) {
                    final coupon = displayCoupons[index];
                    final isApplicable = cartAmount >= coupon.minAmount;
                    final remaining = coupon.minAmount - cartAmount;
                    return _CouponCard(
                      coupon: coupon,
                      isApplicable: isApplicable,
                      remainingAmount: remaining,
                      onApply: () {
                        if (isApplicable) {
                          Navigator.pop(context, coupon.toMap());
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No coupons available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for exciting offers',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isApplicable;
  final double remainingAmount;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.isApplicable,
    required this.remainingAmount,
    required this.onApply,
  });

  String _getMainDescription() {
    switch (coupon.couponType) {
      case 'free_delivery':
        return coupon.minAmount > 0
            ? 'Free Delivery on orders above ₹${coupon.minAmount.toInt()}'
            : 'Free Delivery on this order';
      case 'flat_off':
        return coupon.minAmount > 0
            ? 'Save ₹${coupon.discount.toInt()} on orders above ₹${coupon.minAmount.toInt()}'
            : 'Save ₹${coupon.discount.toInt()} on this order';
      case 'discount':
        final maxStr = coupon.maxDiscountableAmount > 0
            ? ' (max ₹${coupon.maxDiscountableAmount})'
            : '';
        return '${coupon.discount.toInt()}% off$maxStr';
      default:
        return coupon.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final addMoreMsg = !isApplicable && remainingAmount > 0
        ? 'Shop for ₹${remainingAmount.toStringAsFixed(0)} more to apply offer'
        : '';

    return GestureDetector(
      onTap: isApplicable ? onApply : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kBandiwalaYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: kBandiwalaYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.couponCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMainDescription(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: isApplicable ? onApply : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isApplicable
                          ? null
                          : Colors.grey.shade100,
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: isApplicable
                            ? kBandiwalaYellow
                            : Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DottedLinePainter(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.description.isNotEmpty
                        ? coupon.description
                        : _getMainDescription(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  if (addMoreMsg.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      addMoreMsg,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kBandiwalaYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
