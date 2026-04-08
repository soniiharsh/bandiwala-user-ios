import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_page.dart';
import 'cart_page.dart';
import '../widgets/active_order_bar.dart';
import '../widgets/cart_bar.dart';
import '../providers/user_provider.dart';
import '../providers/active_address_provider.dart';
import '../core/navigation/app_page_route.dart';
import '../widgets/skeletons.dart';
import '../models/app_user.dart';
import 'location_picker_page.dart';
import '../core/theme/theme.dart';
import 'orders_page.dart';

class NavPage extends ConsumerStatefulWidget {
  const NavPage({super.key});

  @override
  ConsumerState<NavPage> createState() => _NavPageState();
}

class _NavPageState extends ConsumerState<NavPage> {
  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(userProvider);

    return authAsync.when(
      loading: () => const AppBootSkeleton(),
      error: (_, __) =>
          const Scaffold(body: Center(child: Text('Something went wrong'))),
      data: (appUser) {
        if (appUser == null) return const HomePage();

        if (appUser.savedAddresses.isEmpty) {
          return _ForceAddAddressScreen(
            onAddressAdded: (loc) =>
                ref.read(activeAddressProvider.notifier).setAddress(loc),
          );
        }

        return Scaffold(
          body: const HomePage(),
          bottomNavigationBar: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActiveOrderBar(
                  onViewTap: () {
                    Navigator.of(
                      context,
                    ).push(AppPageRoute(builder: (_) => const OrdersPage()));
                  },
                ),
                CartBar(
                  onTap: () {
                    Navigator.of(context).push(
                      AppPageRoute(
                        builder: (_) => CartPage(
                          onBackToHome: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ForceAddAddressScreen extends StatelessWidget {
  final void Function(SavedAddress) onAddressAdded;
  const _ForceAddAddressScreen({required this.onAddressAdded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_location_alt_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add a delivery address',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We need your address to show vendors near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<SavedAddress>(
                        context,
                        AppPageRoute(
                          type: PageTransitionType.slideUp,
                          builder: (_) => const LocationPickerPage(),
                        ),
                      );
                      if (result != null) onAddressAdded(result);
                    },
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text(
                      'Add Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
}
