import 'package:flutter/material.dart';

class BandiwalaBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const BandiwalaBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const Color bandiwalaYellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: bandiwalaYellow,
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: onItemSelected,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.help_outline),
          activeIcon: Icon(Icons.help),
          label: 'Help',
        ),
      ],
    );
  }
}
// TODO Implement this library.