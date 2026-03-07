// active_order_bar.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kYellow = Color(0xFFFFC107);
const _kYellowDark = Color(0xFFE6AC00);
const _kDark = Color(0xFF1A1A1A);

class ActiveOrderBar extends StatefulWidget {
  final VoidCallback onViewTap;

  const ActiveOrderBar({super.key, required this.onViewTap});

  @override
  State<ActiveOrderBar> createState() => _ActiveOrderBarState();
}

class _ActiveOrderBarState extends State<ActiveOrderBar>
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

    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';
    if (phone.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerPhone', isEqualTo: phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aT = (a.data() as Map)['timestamp'] as Timestamp?;
            final bT = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aT == null || bT == null) return 0;
            return bT.compareTo(aT);
          });

        Map<String, dynamic>? activeOrder;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status != 'completed' && status != 'cancelled') {
            activeOrder = data;
            break;
          }
        }

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
            orderData: activeOrder,
            onViewTap: widget.onViewTap,
            onDismiss: _dismiss,
          ),
        );
      },
    );
  }
}

// ─── Status Bar Widget ────────────────────────────────────────────────────────

class _OrderStatusBar extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onViewTap;
  final VoidCallback onDismiss;

  const _OrderStatusBar({
    required this.orderData,
    required this.onViewTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final status = (orderData['status'] ?? 'confirmed')
        .toString()
        .toLowerCase();
    final orderId = (orderData['orderId'] ?? '').toString();
    final shortId = orderId.length > 12
        ? orderId.substring(orderId.length - 8)
        : orderId;
    final grandTotal = orderData['grandTotal'] ?? 0.0;
    final paymentMethod = (orderData['paymentMethod'] ?? '')
        .toString()
        .toLowerCase();

    final config = _statusConfig(status);

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
            color: _kYellow.withOpacity(0.45),
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
          splashColor: Colors.black.withOpacity(0.06),
          highlightColor: Colors.black.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // ── Pulsing icon ────────────────────────────────────────
                _PulseIcon(icon: config.icon),
                const SizedBox(width: 10),

                // ── Text block ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label + order ID chip
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
                              color: Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$shortId',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kDark.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Subtitle + amount + COD chip
                      Row(
                        children: [
                          Text(
                            config.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: _kDark.withOpacity(0.72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _kDark.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${(grandTotal as num).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kDark.withOpacity(0.85),
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
                                color: Colors.black.withOpacity(0.12),
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

                // ── View button ─────────────────────────────────────────
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

                // ── Dismiss button ──────────────────────────────────────
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 13,
                      color: _kDark.withOpacity(0.8),
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

// ─── Status Config ────────────────────────────────────────────────────────────

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

// ─── Pulsing Icon ─────────────────────────────────────────────────────────────

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
      // ✅ Icon always dark on yellow background
      child: Icon(widget.icon, size: 22, color: _kDark),
    );
  }
}
