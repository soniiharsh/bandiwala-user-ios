import 'package:flutter/material.dart';
import 'cart_store.dart';
import 'location_picker_page.dart';
import 'payment_page.dart'; // ✅ ADDED PAYMENT PAGE IMPORT

const kBandiwalaYellow = Color(0xFFFFC107);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _showPriceBreakdown = false;
  final TextEditingController _addressController = TextEditingController(); // ✅ NEW

  @override
  void initState() {
    super.initState();
    cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartStore.removeListener(_onCartChanged);
    _addressController.dispose(); // ✅ DISPOSE CONTROLLER
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  // ✅ NEW: Navigate to location picker
  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (!mounted) return;

    if (result is SavedLocation) {
      setState(() {
        _addressController.text = result.address;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery address set: ${result.address}'),
          backgroundColor: kBandiwalaYellow,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = cartStore.hasItems;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  hasItems ? '${cartStore.totalItemCount} items' : '0 items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: !hasItems
                ? _buildEmptyState()
                : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              children: [
                ...cartStore.cartByVendor.entries.map(
                      (entry) => _VendorCartSection(
                    vendorId: entry.key,
                    vendorCart: entry.value,
                    onQuantityChanged: (itemId, delta) {
                      cartStore.updateQuantity(
                        vendorId: entry.key,
                        itemId: itemId,
                        delta: delta,
                      );
                    },
                    vendorTotal: cartStore.vendorTotal(entry.key),
                  ),
                ),
                const SizedBox(height: 16),
                _LocationAndCouponSection(
                  addressController: _addressController,
                  onTapLocation: _pickDeliveryLocation,
                ),
              ],
            ),
          ),

          // Grand total + place order
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: hasItems
                      ? () {
                    setState(() {
                      _showPriceBreakdown = !_showPriceBreakdown;
                    });
                  }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const Text(
                        'Grand total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _showPriceBreakdown
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const Spacer(),
                      Text(
                        '₹${cartStore.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showPriceBreakdown && hasItems) ...[
                  const SizedBox(height: 4),
                  _PriceBreakdown(grandTotal: cartStore.grandTotal),
                ],

                const SizedBox(height: 12),
                // ✅ UPDATED: Place Order -> Payment Page
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: hasItems
                        ? () {
                      // Navigate to PaymentPage instead of snackbar
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            amount: cartStore.grandTotal,
                            deliveryAddress: _addressController.text.isNotEmpty
                                ? _addressController.text
                                : null,
                          ),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBandiwalaYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Place order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items from nearby vendors',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-vendor section with items and subtotal
class _VendorCartSection extends StatelessWidget {
  final String vendorId;
  final VendorCart vendorCart;
  final void Function(String itemId, int delta) onQuantityChanged;
  final double vendorTotal;

  const _VendorCartSection({
    required this.vendorId,
    required this.vendorCart,
    required this.onQuantityChanged,
    required this.vendorTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendorCart.vendorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...vendorCart.items.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CartLineItem(
                  item: item,
                  onQuantityChanged: (delta) =>
                      onQuantityChanged(item.id, delta),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: ₹${vendorTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line in the vendor section (name, edit, qty, price)
class _CartLineItem extends StatelessWidget {
  final CartItem item;
  final void Function(int delta) onQuantityChanged;

  const _CartLineItem({
    required this.item,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: const Icon(
            Icons.change_history,
            size: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 12,
                      color: kBandiwalaYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: kBandiwalaYellow,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kBandiwalaYellow,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyButton(
                    icon: Icons.remove,
                    onTap: () => onQuantityChanged(-1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _qtyButton(
                    icon: Icons.add,
                    onTap: () => onQuantityChanged(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Icon(
        icon,
        size: 16,
        color: kBandiwalaYellow,
      ),
    );
  }
}

/// ✅ UPDATED: Location + Coupon section with location picker
class _LocationAndCouponSection extends StatelessWidget {
  final TextEditingController addressController;
  final VoidCallback onTapLocation;

  const _LocationAndCouponSection({
    required this.addressController,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTapLocation,
          child: AbsorbPointer(
            // Prevents keyboard from opening on tap
            child: TextField(
              controller: addressController,
              readOnly: true, // ✅ Makes it non-editable
              decoration: InputDecoration(
                hintText: 'Add your address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBandiwalaYellow),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Coupon code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter coupon code',
            suffixIcon: TextButton(
              onPressed: null,
              child: Text(
                'Apply',
                style: TextStyle(
                  color: kBandiwalaYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final double grandTotal;

  const _PriceBreakdown({required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    final double itemTotal = grandTotal;
    final double delivery = 30;
    final double taxes = (itemTotal + delivery) * 0.05;
    final double finalTotal = itemTotal + delivery + taxes;

    return Column(
      children: [
        _row('Items total', '₹${itemTotal.toStringAsFixed(0)}'),
        _row('Delivery charges', '₹${delivery.toStringAsFixed(0)}'),
        _row('Taxes & fees', '₹${taxes.toStringAsFixed(0)}'),
        const Divider(height: 16),
        _row(
          'To pay',
          '₹${finalTotal.toStringAsFixed(0)}',
          isBold: true,
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
