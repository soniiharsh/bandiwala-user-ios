// cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../providers/active_address_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import '../models/app_user.dart';
import 'location_picker_page.dart';
import 'payment_page.dart';
import 'login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/theme.dart';

const kBandiwalaYellow = AppColors.primary;

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
      MaterialPageRoute(
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
      MaterialPageRoute(
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
              backgroundColor: kBandiwalaYellow,
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
    final authState = ref.watch(userProvider);

    // Auth gate — show login screen if not authenticated
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kBandiwalaYellow)),
      ),
      error: (_, __) => _buildLoginGate(),
      data: (user) {
        if (user == null) return _buildLoginGate();
        return _buildCartContent();
      },
    );
  }

  Widget _buildLoginGate() {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Login to continue',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please login to view your cart and place orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
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
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBandiwalaYellow,
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

  Widget _buildCartContent() {
    final cart = ref.watch(cartProvider);
    final hasItems = cart.hasItems;

    ref.listen<SavedAddress?>(activeAddressProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() => _selectedAddress = next);
      }
    });
    _selectedAddress ??= ref.read(activeAddressProvider);

    // Collect provider-based availability
    final Map<String, bool> itemAvailability = {};
    final Map<String, bool> vendorOnlineStatus = {};

    for (final vendorEntry in cart.cartByVendor.entries) {
      final vendorId = vendorEntry.key;
      final vendorAsync = ref.watch(vendorStreamProvider(vendorId));
      vendorOnlineStatus[vendorId] =
          vendorAsync.valueOrNull?.isAvailable ?? true;

      for (final item in vendorEntry.value.items) {
        final itemAsync = ref.watch(itemStreamProvider(item.id));
        itemAvailability[item.id] = itemAsync.valueOrNull?.isAvailable ?? true;
      }
    }

    final hasUnavailableItems = cart.cartByVendor.entries.any((e) {
      if (vendorOnlineStatus[e.key] == false) return true;
      return e.value.items.any((item) => itemAvailability[item.id] == false);
    });
    final hasVendorOffline = cart.cartByVendor.keys.any(
      (id) => vendorOnlineStatus[id] == false,
    );

    final vendorIds = cart.cartByVendor.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
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
                        color: kBandiwalaYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.totalItemCount} items',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
                          return VendorCartSection(
                            vendorId: entry.key,
                            vendorCart: entry.value,
                            itemAvailability: itemAvailability,
                            isVendorOnline: isVendorOnline,
                            onQuantityChanged: (itemId, delta) {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(
                                    vendorId: entry.key,
                                    itemId: itemId,
                                    delta: delta,
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
                itemAvailability: itemAvailability,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required bool hasUnavailableItems,
    required bool hasVendorOffline,
    required Map<String, bool> itemAvailability,
  }) {
    final cart = ref.read(cartProvider);
    final bool disableCheckout =
        _selectedAddress == null || hasVendorOffline || hasUnavailableItems;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  const Text(
                    'Items Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${cart.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
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
                          color: Colors.deepOrange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Unavailable items strip
          if (hasUnavailableItems && !hasVendorOffline)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Some items are currently unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: disableCheckout ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: disableCheckout
                    ? Colors.grey.shade300
                    : kBandiwalaYellow,
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
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from nearby vendors',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
    final hasAddress = selectedAddress != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAddress ? Colors.green.shade300 : Colors.grey.shade300,
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
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasAddress ? Icons.location_on : Icons.add_location_alt,
                    color: hasAddress ? Colors.green : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hasAddress ? 'Delivery Address' : 'Add Address',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!hasAddress) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                          if (hasAddress && selectedAddress!.label != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kBandiwalaYellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedAddress!.label!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAddress
                            ? selectedAddress!.geolocation
                            : 'Tap to select location',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasAddress
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasAddress &&
                          selectedAddress!.address != null &&
                          selectedAddress!.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            selectedAddress!.address!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade600,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Complete your meal with',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 175,
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

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 95,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        placeholder: (_, __) => Container(
                          width: 140,
                          height: 95,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kBandiwalaYellow,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 140,
                          height: 95,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, size: 28),
                        ),
                      )
                    : Container(
                        width: 140,
                        height: 95,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant, size: 28),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
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
  final void Function(String itemId, int delta) onQuantityChanged;
  final double vendorTotal;

  const VendorCartSection({
    super.key,
    required this.vendorId,
    required this.vendorCart,
    required this.itemAvailability,
    required this.isVendorOnline,
    required this.onQuantityChanged,
    required this.vendorTotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    color: kBandiwalaYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 18,
                    color: kBandiwalaYellow,
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
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Items
          ...vendorCart.items.map((item) {
            final isAvailable = itemAvailability[item.id] ?? true;
            final isDisabled = !isVendorOnline || !isAvailable;

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
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDisabled
                                ? Colors.grey.shade400
                                : Colors.black54,
                          ),
                        ),
                        if (!isAvailable && isVendorOnline)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Currently unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade600,
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
                          ? Colors.grey.shade100
                          : const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () => onQuantityChanged(item.id, -1),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: isDisabled
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDisabled
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () => onQuantityChanged(item.id, 1),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: isDisabled
                                  ? Colors.grey.shade400
                                  : Colors.black87,
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
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${vendorTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
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
