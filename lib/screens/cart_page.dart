// cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../providers/active_address_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import '../models/app_user.dart';
import '../models/vendor.dart';
import '../models/item.dart';
import 'location_picker_page.dart';
import 'payment_page.dart';
import 'login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';
import '../core/navigation/app_page_route.dart';

const kBandiWalaYellow = AppColors.primary;

// ─── CartPage ─────────────────────────────────────────────────────────────────

class CartPage extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;

  const CartPage({super.key, this.onBackToHome});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addressKey = GlobalKey();
  SavedAddress? _selectedAddress;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      AppPageRoute(
        type: PageTransitionType.slideUp,
        builder: (_) => LocationPickerPage(activeAddress: _selectedAddress),
      ),
    );
    if (!mounted) return;
    if (result is SavedAddress) {
      await ref.read(activeAddressProvider.notifier).setAddress(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Delivery address updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _scrollToAddress() {
    final ctx = _addressKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Please add delivery address to continue')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  void _handlePlaceOrder() {
    if (_selectedAddress == null) {
      _scrollToAddress();
      return;
    }
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => PaymentPage(
          itemsTotal: ref.read(cartProvider).grandTotal,
          deliveryLocation: _selectedAddress,
        ),
      ),
    );
  }

  void _showUnavailableItemsDialog(List<String> unavailableItemIds) {
    final cart = ref.read(cartProvider);
    final names = <String>[];
    for (final vendor in cart.cartByVendor.values) {
      for (final item in vendor.items) {
        if (unavailableItemIds.contains(item.id)) names.add(item.name);
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.blue, size: 26),
            SizedBox(width: 10),
            Text(
              'Items Offline',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Some items in your cart are currently not available. Please remove them to continue:',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            ...names.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiWalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleBack() => widget.onBackToHome?.call();

  @override
  Widget build(BuildContext context) {
    ref.listen<SavedAddress?>(activeAddressProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() => _selectedAddress = next);
      }
    });

    final authState = ref.watch(userProvider);

    // Auth gate — show login screen if not authenticated
    final vendorsAsync = ref.watch(vendorsStreamProvider);
    final itemsAsync = ref.watch(allItemsStreamProvider);

    if (authState.isLoading || vendorsAsync.isLoading || itemsAsync.isLoading) {
      return const CartLoadingSkeleton();
    }

    return authState.when(
      loading: () => const CartLoadingSkeleton(),
      error: (_, __) => _buildLoginGate(),
      data: (user) {
        if (user == null) return _buildLoginGate();
        return _buildCartContent(vendorsAsync, itemsAsync);
      },
    );
  }

  Widget _buildLoginGate() {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text(
                    'Your Cart',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Login to continue',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please login to view your cart and place orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              AppPageRoute(
                                type: PageTransitionType.scale,
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBandiWalaYellow,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
      AsyncValue<List<Vendor>> vendorsAsync, AsyncValue<List<Item>> itemsAsync) {
    final cart = ref.watch(cartProvider);
    final hasItems = cart.hasItems;

    _selectedAddress ??= ref.read(activeAddressProvider);

    final List<Vendor> allVendorsList = vendorsAsync.valueOrNull ?? [];
    final List<Item> allItemsList = itemsAsync.valueOrNull ?? [];

    final Map<String, bool> itemAvailability = {};
    final Map<String, bool> vendorOnlineStatus = {};
    final Map<String, bool> vendorPickupSupport = {};
    final Map<String, bool> vendorDeliverySupport = {};

    for (final vendorEntry in cart.cartByVendor.entries) {
      final vendorId = vendorEntry.key;
      final vendor = allVendorsList.firstWhere((v) => v.id == vendorId,
          orElse: () => Vendor(
                id: vendorId,
                name: '',
                phone: '',
                imageUrl: '',
                address: '',
                category: '',
                isAvailable: false,
                rating: 0,
              ));

      vendorOnlineStatus[vendorId] = vendor.isAvailable;
      vendorPickupSupport[vendorId] = vendor.isPickupAvailable;
      vendorDeliverySupport[vendorId] = vendor.isDeliveryAvailable;

      for (final itemInCart in vendorEntry.value.items) {
        final item = allItemsList.firstWhere((i) => i.id == itemInCart.id,
            orElse: () => Item(
                  id: itemInCart.id,
                  vendorId: vendorId,
                  name: '',
                  price: 0,
                  imageUrl: '',
                  category: '',
                  isAvailable: false,
                  description: '',
                  isVeg: true,
                ));
        itemAvailability[itemInCart.id] = item.isAvailable;
      }
    }

    final hasUnavailableItems = cart.cartByVendor.entries.any((e) {
      if (vendorOnlineStatus[e.key] == false) return true;
      return e.value.items.any((item) => itemAvailability[item.id] == false);
    });
    final hasVendorOffline = cart.cartByVendor.keys.any(
      (id) => vendorOnlineStatus[id] == false,
    );

    // Fulfillment Compatibility
    final vendorIds = cart.cartByVendor.keys.toList();
    final allSupportPickup =
        vendorIds.isNotEmpty && vendorIds.every((id) => vendorPickupSupport[id] ?? false);
    final allSupportDelivery =
        vendorIds.isNotEmpty && vendorIds.every((id) => vendorDeliverySupport[id] ?? false);
    final hasIncompatibleFulfillment =
        vendorIds.isNotEmpty && !allSupportPickup && !allSupportDelivery;

    // Determine which vendors to remove to resolve incompatibility
    final deliveryOnlyIds =
        vendorIds.where((id) => (vendorDeliverySupport[id] ?? false)).toList();
    final pickupOnlyIds =
        vendorIds.where((id) => (vendorPickupSupport[id] ?? false)).toList();
    final bothSupportIds = vendorIds
        .where((id) => (vendorDeliverySupport[id] ?? false) && (vendorPickupSupport[id] ?? false))
        .toList();
    final neitherSupportIds = vendorIds
        .where((id) => !(vendorDeliverySupport[id] ?? false) && !(vendorPickupSupport[id] ?? false))
        .toList();

    final canCleanup = hasUnavailableItems || hasVendorOffline || hasIncompatibleFulfillment;

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Home',
                  ),
                  const Text(
                    'Your Cart',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (hasItems)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kBandiWalaYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.totalItemCount} items',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: !hasItems
                  ? _buildEmptyState()
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                          ...cart.cartByVendor.entries.map((entry) {
                            final isVendorOnline =
                                vendorOnlineStatus[entry.key] ?? true;
                            final supportsPickup =
                                vendorPickupSupport[entry.key] ?? false;
                            final supportsDelivery =
                                vendorDeliverySupport[entry.key] ?? false;

                            return VendorCartSection(
                              vendorId: entry.key,
                              vendorCart: entry.value,
                              itemAvailability: itemAvailability,
                              isVendorOnline: isVendorOnline,
                              supportsPickup: supportsPickup,
                              supportsDelivery: supportsDelivery,
                              onQuantityChanged:
                                  (itemId, delta, {String? cartKey}) {
                                ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(
                                      vendorId: entry.key,
                                      itemId: itemId,
                                      delta: delta,
                                      cartKey: cartKey,
                                    );
                              },
                              vendorTotal: cart.vendorTotal(entry.key),
                            );
                          }),

                        if (vendorIds.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          YouMayLikeSection(vendorIds: vendorIds),
                        ],

                        const SizedBox(height: 20),

                        AddressSection(
                          key: _addressKey,
                          selectedAddress: _selectedAddress,
                          onTapLocation: _pickDeliveryLocation,
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
            ),

            if (hasItems)
              _buildBottomBar(
                hasUnavailableItems: hasUnavailableItems,
                hasVendorOffline: hasVendorOffline,
                hasIncompatibleFulfillment: hasIncompatibleFulfillment,
                itemAvailability: itemAvailability,
                vendorOnlineStatus: vendorOnlineStatus,
                vendorDeliverySupport: vendorDeliverySupport,
                vendorPickupSupport: vendorPickupSupport,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required bool hasUnavailableItems,
    required bool hasVendorOffline,
    required bool hasIncompatibleFulfillment,
    required Map<String, bool> itemAvailability,
    required Map<String, bool> vendorOnlineStatus,
    required Map<String, bool> vendorDeliverySupport,
    required Map<String, bool> vendorPickupSupport,
  }) {
    final cart = ref.read(cartProvider);
    final bool disableCheckout =
        _selectedAddress == null ||
        hasVendorOffline ||
        hasUnavailableItems ||
        hasIncompatibleFulfillment;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${cart.grandTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Spacer(),
            ],
          ),

          // Vendor offline strip
          if (hasVendorOffline)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepOrange.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'One or more vendors are currently offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.orange.shade300
                              : Colors.deepOrange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Unavailable items strip
          if (hasUnavailableItems && !hasVendorOffline && !hasIncompatibleFulfillment)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withOpacity(0.15)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.red.shade800 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some items are currently unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showUnavailableItemsDialog(
                        itemAvailability.entries
                            .where((e) => !e.value)
                            .map((e) => e.key)
                            .toList(),
                      ),
                      child: Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Incompatible fulfillment strip
          if (hasIncompatibleFulfillment && !hasVendorOffline)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue.shade800 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mixed fulfillment options in cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Cleanup Option
          if (hasVendorOffline || hasUnavailableItems || hasIncompatibleFulfillment)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: InkWell(
                onTap: () => _showCleanupDialog(
                  vendorOnlineStatus: vendorOnlineStatus,
                  itemAvailability: itemAvailability,
                  vendorDeliverySupport: vendorDeliverySupport,
                  vendorPickupSupport: vendorPickupSupport,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cleaning_services_rounded,
                        size: 14,
                        color: kBandiWalaYellow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CLEANUP CART TO CHECKOUT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kBandiWalaYellow,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Delivering to indicator
          if (_selectedAddress != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Delivering to ${_selectedAddress!.geolocation.split(',').first.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: disableCheckout ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: disableCheckout
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                    : kBandiWalaYellow,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedAddress == null
                    ? 'Select Delivery Address'
                    : hasVendorOffline
                    ? 'Vendor Offline — Cannot Checkout'
                    : hasUnavailableItems
                    ? 'Remove Unavailable Items'
                    : hasIncompatibleFulfillment
                    ? 'Resolve Fulfillment Conflict'
                    : 'Proceed to Checkout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from nearby vendors',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog({
    required Map<String, bool> vendorOnlineStatus,
    required Map<String, bool> itemAvailability,
    required Map<String, bool> vendorDeliverySupport,
    required Map<String, bool> vendorPickupSupport,
  }) {
    final cart = ref.read(cartProvider);
    final vendorIds = cart.cartByVendor.keys.toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services_rounded, color: kBandiWalaYellow, size: 24),
            const SizedBox(width: 12),
            const Text('Cleanup Cart', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'We will remove offline vendors, unavailable items, and resolve fulfillment conflicts so you can proceed to checkout.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final itemsToRemove = <String>[];
              final vendorsToRemove = <String>[];

              // Determine dominant fulfillment method
              int deliverySupportCount =
                  vendorIds.where((id) => vendorDeliverySupport[id] ?? false).length;
              int pickupSupportCount =
                  vendorIds.where((id) => vendorPickupSupport[id] ?? false).length;

              bool preferDelivery = deliverySupportCount >= pickupSupportCount;

              for (final id in vendorIds) {
                if (!(vendorOnlineStatus[id] ?? true)) {
                  vendorsToRemove.add(id);
                  continue;
                }

                if (preferDelivery && !(vendorDeliverySupport[id] ?? false)) {
                  vendorsToRemove.add(id);
                  continue;
                }

                if (!preferDelivery && !(vendorPickupSupport[id] ?? false)) {
                  vendorsToRemove.add(id);
                  continue;
                }

                // Check items in this vendor
                final vc = cart.cartByVendor[id];
                if (vc != null) {
                  for (final item in vc.items) {
                    if (!(itemAvailability[item.id] ?? true)) {
                      itemsToRemove.add(item.id);
                    }
                  }
                }
              }

              for (final vid in vendorsToRemove) {
                ref.read(cartProvider.notifier).removeVendor(vid);
              }
              if (itemsToRemove.isNotEmpty) {
                ref.read(cartProvider.notifier).removeItems(itemsToRemove);
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleaned up!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiWalaYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}


// ─── AddressSection ───────────────────────────────────────────────────────────

class AddressSection extends StatelessWidget {
  final SavedAddress? selectedAddress;
  final VoidCallback onTapLocation;

  const AddressSection({
    super.key,
    required this.selectedAddress,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasAddress = selectedAddress != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAddress
              ? (isDark ? Colors.green.shade700 : Colors.green.shade300)
              : theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapLocation,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasAddress
                        ? (isDark
                              ? Colors.green.withOpacity(0.15)
                              : Colors.green.shade50)
                        : (isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasAddress ? Icons.location_on : Icons.add_location_alt,
                    color: hasAddress
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row — never truncates
                      Text(
                        hasAddress ? 'Delivery Address' : 'Add Address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Label / Required badge
                      if (!hasAddress)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.withOpacity(0.15)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.red.shade300
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      if (hasAddress && selectedAddress!.label != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kBandiWalaYellow.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            selectedAddress!.label!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      // Address (door/flat)
                      if (hasAddress &&
                          selectedAddress!.address != null &&
                          selectedAddress!.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedAddress!.address!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Geolocation (area)
                      if (hasAddress) ...[
                        const SizedBox(height: 2),
                        Text(
                          selectedAddress!.geolocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select location',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── YouMayLikeSection ────────────────────────────────────────────────────────

class YouMayLikeSection extends ConsumerWidget {
  final List<String> vendorIds;
  const YouMayLikeSection({super.key, required this.vendorIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItemIds = <String>{
      for (var vc in cart.cartByVendor.values)
        for (var item in vc.items) item.id,
    };

    final allItems = _getVendorItems(
      vendorIds,
      ref,
    ).where((item) => !cartItemIds.contains(item['id'])).toList();

    if (allItems.isEmpty) return const SizedBox.shrink();
    allItems.shuffle();
    final displayItems = allItems.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Complete your meal with',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: displayItems.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                right: index == displayItems.length - 1 ? 0 : 10,
              ),
              child: SuggestionCard(item: displayItems[index]),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getVendorItems(
    List<String> vendorIds,
    WidgetRef ref,
  ) {
    final allItems = <Map<String, dynamic>>[];
    for (final vendorId in vendorIds) {
      final vendorName =
          ref.read(vendorStreamProvider(vendorId)).value?.name ?? 'Restaurant';
      final items =
          ref.read(availableItemsForVendorProvider(vendorId)).valueOrNull ?? [];
      for (final item in items) {
        allItems.add({
          'id': item.id,
          'vendorId': vendorId,
          'vendorName': vendorName,
          'name': item.name,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'description': item.description,
          'isVeg': item.isVeg,
        });
      }
    }
    return allItems;
  }
}

// ─── SuggestionCard ───────────────────────────────────────────────────────────

class SuggestionCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  const SuggestionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = item['name'] ?? 'Item';
    final price = (item['price'] ?? 0).toDouble();
    final imageUrl = item['imageUrl'] ?? '';
    final isVeg = item['isVeg'] ?? true;
    final itemId = item['id'] ?? '';
    final vendorId = item['vendorId'] ?? '';
    final vendorName = item['vendorName'] ?? 'Restaurant';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 140,
                        height: 110,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        placeholder: (_, __) => Container(
                          width: 140,
                          height: 110,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 140,
                          height: 110,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.restaurant,
                            size: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 140,
                        height: 110,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.restaurant,
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isVeg ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isVeg ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.12),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              vendorId: vendorId,
                              vendorName: vendorName,
                              itemId: itemId,
                              itemName: name,
                              price: price,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Icon(
                        Icons.add,
                        color: Colors.pink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

// ─── VendorCartSection ────────────────────────────────────────────────────────

class VendorCartSection extends ConsumerWidget {
  final String vendorId;
  final VendorCart vendorCart;
  final Map<String, bool> itemAvailability;
  final bool isVendorOnline;
  final void Function(String itemId, int delta, {String? cartKey})
  onQuantityChanged;
  final double vendorTotal;

  final bool supportsPickup;
  final bool supportsDelivery;

  const VendorCartSection({
    super.key,
    required this.vendorId,
    required this.vendorCart,
    required this.itemAvailability,
    required this.isVendorOnline,
    required this.supportsPickup,
    required this.supportsDelivery,
    required this.onQuantityChanged,
    required this.vendorTotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBandiWalaYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 18,
                    color: kBandiWalaYellow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vendorCart.vendorName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isVendorOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.deepOrange.withOpacity(0.15)
                          : Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.deepOrange.shade300
                            : Colors.deepOrange.shade700,
                      ),
                    ),
                  )
                else ...[
                  if (supportsDelivery)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.delivery_dining_rounded, size: 16, color: Colors.green),
                    ),
                  if (supportsPickup)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.blue),
                    ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Items
          ...vendorCart.items.map((item) {
            final isAvailable = itemAvailability[item.id] ?? true;
            final isDisabled = !isVendorOnline || !isAvailable;
            // Always allow decrement so the user can remove unavailable/offline vendor items.
            // Only block increment when the vendor/item is unavailable.
            final blockIncrement = isDisabled;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Show customization details
                        if (item.selectedOption != null ||
                            item.selectedAddons.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [
                                    if (item.selectedOption != null)
                                      item.selectedOption!['name'],
                                    ...item.selectedAddons.map(
                                      (a) => a['name'],
                                    ),
                                  ]
                                  .where(
                                    (s) => s != null && s.toString().isNotEmpty,
                                  )
                                  .join(', '),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDisabled
                                    ? theme.colorScheme.onSurface.withOpacity(0.2)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${item.totalUnitPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDisabled
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isAvailable && isVendorOnline)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Currently unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.red.shade400
                                    : Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Quantity stepper
                  Container(
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? (isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.grey.shade100)
                          : (isDark
                                ? const Color(0xFF423B22)
                                : const Color(0xFFFFF3CD)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => onQuantityChanged(
                            item.id,
                            -1,
                            cartKey: item.cartKey,
                          ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: isDark ? kBandiWalaYellow : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDisabled
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        GestureDetector(
                          onTap: blockIncrement
                              ? null
                              : () => onQuantityChanged(
                                  item.id,
                                  1,
                                  cartKey: item.cartKey,
                                ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: blockIncrement
                                  ? theme.colorScheme.onSurface.withOpacity(0.3)
                                  : (isDark
                                        ? kBandiWalaYellow
                                        : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Vendor subtotal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${vendorTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
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
