import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';

const _kYellow = AppColors.primary;

/// Shows a bottom sheet for selecting options (radio) and addons (checkbox)
/// before adding an item to the cart.
void showItemCustomizationSheet({
  required BuildContext context,
  required String vendorId,
  required String vendorName,
  required Item item,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ItemCustomizationSheet(
      vendorId: vendorId,
      vendorName: vendorName,
      item: item,
    ),
  );
}

class ItemCustomizationSheet extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final Item item;

  const ItemCustomizationSheet({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.item,
  });

  @override
  ConsumerState<ItemCustomizationSheet> createState() =>
      _ItemCustomizationSheetState();
}

class _ItemCustomizationSheetState
    extends ConsumerState<ItemCustomizationSheet> {
  Map<String, dynamic>? _selectedOption;
  final Set<int> _selectedAddonIndices = {};

  List<Map<String, dynamic>> get _availableOptions => widget.item.availableOptions;

  List<Map<String, dynamic>> get _availableAddons => widget.item.availableAddons;

  bool get _hasOptions => _availableOptions.isNotEmpty;
  bool get _hasAddons => _availableAddons.isNotEmpty;

  double get _basePrice => widget.item.price;

  double get _optionExtra =>
      _selectedOption != null
          ? ((_selectedOption!['price'] ?? 0) as num).toDouble()
          : 0.0;

  double get _addonsExtra {
    double total = 0;
    final addons = _availableAddons;
    for (final idx in _selectedAddonIndices) {
      total += ((addons[idx]['price'] ?? 0) as num).toDouble();
    }
    return total;
  }

  double get _totalPrice => _basePrice + _optionExtra + _addonsExtra;

  bool get _canAdd => !_hasOptions || _selectedOption != null;

  void _addToCart() {
    final selectedAddons = _selectedAddonIndices
        .map((i) => _availableAddons[i])
        .toList();

    ref.read(cartProvider.notifier).addItem(
          vendorId: widget.vendorId,
          vendorName: widget.vendorName,
          itemId: widget.item.id,
          itemName: widget.item.name,
          price: widget.item.price,
          selectedOption: _selectedOption,
          selectedAddons: selectedAddons,
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item name + base price
                  Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: widget.item.isVeg ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_basePrice.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),

                  if (widget.item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Options section (radio)
                  if (_hasOptions) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: _kYellow,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Choose an Option',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
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
                          ),
                          const SizedBox(height: 12),
                          ..._availableOptions.map((option) {
                            final isSelected =
                                _selectedOption?['name'] == option['name'];
                            final optPrice =
                                ((option['price'] ?? 0) as num).toDouble();
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedOption = option),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kYellow.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? _kYellow
                                        : (isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected
                                          ? _kYellow
                                          : (isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade400),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (optPrice > 0)
                                      Text(
                                        '+₹${optPrice.toInt()}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Addons section (checkbox)
                  if (_hasAddons) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: _kYellow,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Extras',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.green.shade900
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Optional',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.green.shade300
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_availableAddons.length, (i) {
                            final addon = _availableAddons[i];
                            final isSelected =
                                _selectedAddonIndices.contains(i);
                            final addonPrice =
                                ((addon['price'] ?? 0) as num).toDouble();
                            return InkWell(
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedAddonIndices.remove(i);
                                } else {
                                  _selectedAddonIndices.add(i);
                                }
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kYellow.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? _kYellow
                                        : (isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: isSelected
                                          ? _kYellow
                                          : (isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade400),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        addon['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (addonPrice > 0)
                                      Text(
                                        '+₹${addonPrice.toInt()}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom bar with total and add button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₹${_totalPrice.toInt()}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _kYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canAdd ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canAdd ? _kYellow : Colors.grey.shade400,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _canAdd ? 'Add to Cart' : 'Select Option',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
