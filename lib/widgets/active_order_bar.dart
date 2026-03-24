// active_order_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';
import '../core/theme/theme.dart';

const _kYellow = AppColors.primary;
const _kYellowDark = Color(0xFFE6AC00);
const _kDark = Color(0xFF1A1A1A);

class ActiveOrderBar extends ConsumerStatefulWidget {
  final VoidCallback onViewTap;

  const ActiveOrderBar({super.key, required this.onViewTap});

  @override
  ConsumerState<ActiveOrderBar> createState() => _ActiveOrderBarState();
}

class _ActiveOrderBarState extends ConsumerState<ActiveOrderBar>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final activeOrder = ref.watch(activeOrderProvider);
    if (activeOrder == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: _OrderStatusBar(
        orderId: activeOrder.id,
        status: activeOrder.status,
        grandTotal: activeOrder.grandTotal,
        paymentMethod: activeOrder.paymentMethod,
        onViewTap: widget.onViewTap,
        onDismiss: _dismiss,
      ),
    );
  }
}

class _OrderStatusBar extends StatelessWidget {
  final String orderId;
  final String status;
  final double grandTotal;
  final String paymentMethod;
  final VoidCallback onViewTap;
  final VoidCallback onDismiss;

  const _OrderStatusBar({
    required this.orderId,
    required this.status,
    required this.grandTotal,
    required this.paymentMethod,
    required this.onViewTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 12
        ? orderId.substring(orderId.length - 8)
        : orderId;
    final config = _statusConfig(status.toLowerCase());

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kYellow, _kYellowDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kYellow.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.black.withValues(alpha: 0.06),
          highlightColor: Colors.black.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _PulseIcon(icon: config.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _kDark,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$shortId',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kDark.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            config.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: _kDark.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _kDark.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${grandTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kDark.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (paymentMethod == 'cod') ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _kDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onViewTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _kDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kYellow,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 13,
                      color: _kDark.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'confirmed':
      case 'order_created':
        return const _StatusConfig(
          label: 'Order Confirmed',
          subtitle: 'Your order has been placed',
          icon: Icons.check_circle_rounded,
        );
      case 'preparing':
        return const _StatusConfig(
          label: 'Being Prepared',
          subtitle: 'Your food is being cooked',
          icon: Icons.restaurant_rounded,
        );
      case 'ready':
        return const _StatusConfig(
          label: 'Order Ready',
          subtitle: 'Out for delivery soon',
          icon: Icons.delivery_dining_rounded,
        );
      case 'accepted':
        return const _StatusConfig(
          label: 'Order Accepted',
          subtitle: 'Vendor is getting ready',
          icon: Icons.thumb_up_rounded,
        );
      default:
        return const _StatusConfig(
          label: 'Order Processing',
          subtitle: 'Waiting for update',
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final String subtitle;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  const _PulseIcon({required this.icon});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(widget.icon, size: 22, color: _kDark),
    );
  }
}
