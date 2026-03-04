import 'package:flutter/material.dart';
import 'cart_store.dart';

class BandiwalaBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const BandiwalaBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<BandiwalaBottomNavigation> createState() =>
      _BandiwalaBottomNavigationState();
}

class _BandiwalaBottomNavigationState extends State<BandiwalaBottomNavigation> {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = cartStore.totalItemCount;

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      selectedItemColor: bandiwalaYellow,
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: widget.onItemSelected,
      items: [
        // ── Home ─────────────────────────────────────────────────────────
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),

        // ── Cart ─────────────────────────────────────────────────────────
        BottomNavigationBarItem(
          icon: _CartIcon(count: cartItemCount, filled: false),
          activeIcon: _CartIcon(count: cartItemCount, filled: true),
          label: 'Cart',
        ),

        // ── Orders ───────────────────────────────────────────────────────
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ],
    );
  }
}

// ── Cart icon with badge ──────────────────────────────────────────────────────
class _CartIcon extends StatelessWidget {
  final int count;
  final bool filled;
  const _CartIcon({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(filled ? Icons.shopping_cart : Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: EdgeInsets.all(count > 9 ? 4 : 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
