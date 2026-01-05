import 'package:flutter/material.dart';
import 'bottom_navigation.dart';
import 'home_page.dart';
import 'vendor_items_page.dart';
import 'settings_screen.dart'; // if needed elsewhere

class RootScreen extends StatefulWidget {
  final String? phoneNumber;
  const RootScreen({super.key, this.phoneNumber});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  // Home tab + cart + help pages are created once and preserved. [web:155]
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(phoneNumber: widget.phoneNumber),
      const CartPage(),
      const HelpPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BandiwalaBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
    );
  }
}

/// Simple cart page wrapper so it can live in RootScreen.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Your cart is empty',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Help & support coming soon',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
