import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coupons_provider.dart';
import '../models/coupon.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';

const kBandiWalaYellow = AppColors.primary;

class CouponsPage extends ConsumerStatefulWidget {
  final double cartAmount;
  final Map<String, double> vendorSubtotals;

  final bool isDelivery;

  const CouponsPage({
    super.key,
    required this.cartAmount,
    this.vendorSubtotals = const {},
    this.isDelivery = false,
  });

  @override
  ConsumerState<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends ConsumerState<CouponsPage> {
  final _searchController = TextEditingController();
  bool _searching = false;
  Coupon? _searchResult;
  // null = not searched yet, true = found, false = not found/invalid
  bool? _searchFound;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _searching = true;
      _searchResult = null;
      _searchFound = null;
    });
    final coupon = await fetchCouponByCode(code);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searchResult = coupon;
      _searchFound = coupon != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalAsync = ref.watch(activeCouponsProvider);
    final vendorCouponAsyncList = widget.vendorSubtotals.keys
        .map((id) => ref.watch(vendorCouponsProvider(id)))
        .toList();
    final redemptionsAsync = ref.watch(couponRedemptionsProvider);

    final isLoading =
        globalAsync.isLoading ||
        vendorCouponAsyncList.any((a) => a.isLoading) ||
        redemptionsAsync.isLoading;
    final hasError =
        globalAsync.hasError || vendorCouponAsyncList.any((a) => a.hasError);

    if (isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const CouponsListSkeleton(),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final globalCoupons = (globalAsync.valueOrNull ?? [])
        .where((c) => widget.isDelivery || c.couponType != 'free_delivery')
        .toList();
    final redemptions = redemptionsAsync.valueOrNull ?? {};

    final Map<String, Coupon> vendorCouponMap = {};
    for (final async in vendorCouponAsyncList) {
      for (final c in (async.valueOrNull ?? [])) {
        vendorCouponMap[c.id] = c;
      }
    }
    final vendorCoupons = vendorCouponMap.values
        .where((c) => widget.isDelivery || c.couponType != 'free_delivery')
        .toList();
    final allEmpty = globalCoupons.isEmpty && vendorCoupons.isEmpty;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else if (_searchFound == true &&
              _searchResult != null &&
              (widget.isDelivery ||
                  _searchResult!.couponType != 'free_delivery'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _CouponCard(
                coupon: _searchResult!,
                isApplicable: _isSearchResultApplicable(
                  _searchResult!,
                  redemptions,
                ),
                remainingAmount:
                    _searchResult!.minAmount - _amountForCoupon(_searchResult!),
                userUsageCount: redemptions[_searchResult!.id] ?? 0,
                onApply: () {
                  if (_isSearchResultApplicable(_searchResult!, redemptions)) {
                    Navigator.pop(context, _searchResult!.toMap());
                  }
                },
              ),
            )
          else if (_searchFound == false ||
              (_searchFound == true &&
                  _searchResult != null &&
                  !widget.isDelivery &&
                  _searchResult!.couponType == 'free_delivery'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No valid coupon found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          Expanded(
            child: allEmpty && _searchFound == null
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (vendorCoupons.isNotEmpty) ...[
                        _sectionHeader('Vendor Offers'),
                        ..._buildVendorCouponCards(
                          context,
                          vendorCoupons,
                          redemptions,
                        ),
                      ],
                      if (globalCoupons.isNotEmpty) ...[
                        _sectionHeader('App-wide Offers'),
                        ..._buildCouponCards(
                          context,
                          globalCoupons,
                          widget.cartAmount,
                          redemptions,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSearchResultApplicable(Coupon c, Map<String, int> redemptions) {
    final base = _amountForCoupon(c);
    if (base < c.minAmount) return false;
    if (c.perUserLimit > 0 && (redemptions[c.id] ?? 0) >= c.perUserLimit)
      return false;
    return true;
  }

  double _amountForCoupon(Coupon c) => c.isGlobal
      ? widget.cartAmount
      : (widget.vendorSubtotals[c.vendorId] ?? 0.0);

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: TextField(
      controller: _searchController,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _onSearch(),
      decoration: InputDecoration(
        hintText: 'Enter coupon code',
        prefixIcon: const Icon(Icons.local_offer_outlined),
        suffixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _onSearch,
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    ),
  );

  AppBar _buildAppBar() => AppBar(
    leading: Builder(
      builder: (ctx) => IconButton(
        onPressed: () => Navigator.pop(ctx),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    title: const Text(
      'Apply coupon',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    centerTitle: false,
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  List<Widget> _buildCouponCards(
    BuildContext context,
    List<Coupon> coupons,
    double base,
    Map<String, int> redemptions,
  ) {
    bool isApplicable(Coupon c) {
      if (base < c.minAmount) return false;
      if (c.perUserLimit > 0 && (redemptions[c.id] ?? 0) >= c.perUserLimit)
        return false;
      return true;
    }

    final sorted = [...coupons]
      ..sort((a, b) {
        final aOk = isApplicable(a) ? 0 : 1;
        final bOk = isApplicable(b) ? 0 : 1;
        return aOk.compareTo(bOk);
      });

    return sorted.map((coupon) {
      final applicable = isApplicable(coupon);
      return _CouponCard(
        coupon: coupon,
        isApplicable: applicable,
        remainingAmount: coupon.minAmount - base,
        userUsageCount: redemptions[coupon.id] ?? 0,
        onApply: () {
          if (applicable) Navigator.pop(context, coupon.toMap());
        },
      );
    }).toList();
  }

  List<Widget> _buildVendorCouponCards(
    BuildContext context,
    List<Coupon> coupons,
    Map<String, int> redemptions,
  ) {
    return coupons.map((coupon) {
      final base = widget.vendorSubtotals[coupon.vendorId] ?? 0.0;
      final userCount = redemptions[coupon.id] ?? 0;
      final applicable =
          base >= coupon.minAmount &&
          (coupon.perUserLimit == 0 || userCount < coupon.perUserLimit);
      return _CouponCard(
        coupon: coupon,
        isApplicable: applicable,
        remainingAmount: coupon.minAmount - base,
        userUsageCount: userCount,
        onApply: () {
          if (applicable) Navigator.pop(context, coupon.toMap());
        },
      );
    }).toList();
  }

  Widget _buildEmptyState() => Center(
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

// ─── Coupon card ──────────────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isApplicable;
  final double remainingAmount;
  final int userUsageCount;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.isApplicable,
    required this.remainingAmount,
    required this.userUsageCount,
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
    final cs = Theme.of(context).colorScheme;
    final addMoreMsg = !isApplicable && remainingAmount > 0
        ? 'Shop for ₹${remainingAmount.toStringAsFixed(0)} more to apply offer'
        : '';
    final limitReached =
        coupon.perUserLimit > 0 && userUsageCount >= coupon.perUserLimit;

    return GestureDetector(
      onTap: isApplicable ? onApply : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
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
                      color: kBandiWalaYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: kBandiWalaYellow,
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
                        // Per-user usage indicator
                        if (coupon.perUserLimit > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: limitReached
                                    ? Colors.red.shade400
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Used $userUsageCount / ${coupon.perUserLimit} times',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: limitReached
                                      ? Colors.red.shade400
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                      limitReached ? 'Limit reached' : 'Apply',
                      style: TextStyle(
                        color: isApplicable
                            ? kBandiWalaYellow
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
                        color: kBandiWalaYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (limitReached) ...[
                    const SizedBox(height: 8),
                    Text(
                      'You\'ve reached the usage limit for this coupon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
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
