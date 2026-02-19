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
    if (mounted) {
      setState(() {});
    }
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined),
              if (cartItemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: EdgeInsets.all(cartItemCount > 9 ? 4 : 5),
                    decoration: BoxDecoration(
                      color: bandiwalaYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        cartItemCount > 99 ? '99+' : cartItemCount.toString(),
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
          ),
          activeIcon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart),
              if (cartItemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: EdgeInsets.all(cartItemCount > 9 ? 4 : 5),
                    decoration: BoxDecoration(
                      color: bandiwalaYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        cartItemCount > 99 ? '99+' : cartItemCount.toString(),
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
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.help_outline),
          activeIcon: Icon(Icons.help),
          label: 'Help',
        ),
      ],
    );
  }
}
