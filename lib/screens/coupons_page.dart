import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class CouponsPage extends StatelessWidget {
  final double cartAmount;
  final List<String> cartVendorIds;
  final Map<String, double> vendorAmounts;
  final Map<String, String> vendorNames;

  const CouponsPage({
    super.key,
    required this.cartAmount,
    required this.cartVendorIds,
    required this.vendorAmounts,
    required this.vendorNames,
  });

  @override
  Widget build(BuildContext context) {
    print('\n🎫 ═══════════════════════════════════════');
    print('     COUPONS PAGE - DETAILED DEBUG      ');
    print('═══════════════════════════════════════');
    print('Cart Total Amount: ₹$cartAmount');
    print('Number of Vendors in Cart: ${cartVendorIds.length}');
    print('\n📦 CART VENDORS:');
    for (int i = 0; i < cartVendorIds.length; i++) {
      final id = cartVendorIds[i];
      final name = vendorNames[id] ?? 'Unknown';
      final amount = vendorAmounts[id] ?? 0;
      print('  [$i] ID: "$id"');
      print('      Name: "$name"');
      print('      Amount: ₹$amount');
      print('      ID Length: ${id.length} chars');
    }
    print('═══════════════════════════════════════\n');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Restaurant coupons',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ ERROR: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kBandiwalaYellow,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('⚠️ No coupons found in database');
            return _buildEmptyState();
          }

          print('\n📋 Found ${snapshot.data!.docs.length} active coupons in database\n');

          final applicableCoupons = <Map<String, dynamic>>[];
          final notApplicableCoupons = <Map<String, dynamic>>[];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final couponData = {
              'id': doc.id,
              ...data,
            };

            final couponCode = couponData['couponCode'] ?? 'UNKNOWN';
            print('╔═══════════════════════════════════════╗');
            print('║  Processing: $couponCode');
            print('╚═══════════════════════════════════════╝');

            // Check usage limit
            final hasUsageLimit = couponData['hasUsageLimit'] ?? false;
            final maxUsage = couponData['maxUsage'];
            final currentUsage = couponData['currentUsage'] ?? 0;

            if (hasUsageLimit && maxUsage != null && currentUsage >= maxUsage) {
              print('❌ SKIPPED - Usage limit reached ($currentUsage/$maxUsage)\n');
              continue;
            }

            final isWholeApp = couponData['isWholeApp'] ?? true;
            final minAmount = (couponData['minAmount'] ?? 0).toDouble();

            print('   Type: ${isWholeApp ? "WHOLE APP" : "VENDOR-SPECIFIC"}');
            print('   Min Amount: ₹$minAmount');

            List<String> applicableVendorIds = [];
            double relevantAmount = 0;
            double remainingAmount = 0;
            bool isApplicable = false;
            bool shouldShowCoupon = true;

            if (isWholeApp) {
              // WHOLE APP COUPON
              print('   📱 Whole App Coupon');
              applicableVendorIds = List.from(cartVendorIds);
              relevantAmount = cartAmount;
              remainingAmount = minAmount - cartAmount;
              isApplicable = cartAmount >= minAmount;

              print('      Cart Total: ₹$cartAmount');
              print('      Is Applicable: ${isApplicable ? "✅ YES" : "❌ NO"}');
              if (!isApplicable) {
                print('      Need: ₹${remainingAmount.toStringAsFixed(0)} more');
              }
            } else {
              // VENDOR-SPECIFIC COUPON
              print('   🏪 Vendor-Specific Coupon');

              final couponVendorIds = List<String>.from(couponData['vendorIds'] ?? []);

              if (couponVendorIds.isEmpty) {
                print('      ❌ No vendor IDs in coupon - HIDING');
                shouldShowCoupon = false;
              } else {
                print('      Required vendors (${couponVendorIds.length}):');
                for (int i = 0; i < couponVendorIds.length; i++) {
                  print('         [$i] "${couponVendorIds[i]}"');
                }

                // FIXED: Better matching logic
                applicableVendorIds = _findMatchingVendors(
                  cartVendorIds: cartVendorIds,
                  couponVendorIds: couponVendorIds,
                  vendorNames: vendorNames,
                );

                print('      Matched: ${applicableVendorIds.length} vendor(s)');

                if (applicableVendorIds.isEmpty) {
                  print('      ❌ NO MATCHING VENDORS - HIDING COUPON');
                  shouldShowCoupon = false;
                } else {
                  // Show matched vendors
                  print('      ✅ Matched vendors:');
                  for (var id in applicableVendorIds) {
                    final name = vendorNames[id] ?? 'Unknown';
                    final amount = vendorAmounts[id] ?? 0;
                    print('         - $name: ₹$amount');
                  }

                  // Calculate total from matching vendors
                  relevantAmount = applicableVendorIds.fold(
                    0.0,
                        (sum, id) => sum + (vendorAmounts[id] ?? 0),
                  );

                  print('      Total from matched: ₹$relevantAmount');
                  print('      Required minimum: ₹$minAmount');

                  remainingAmount = minAmount - relevantAmount;
                  isApplicable = relevantAmount >= minAmount;

                  print('      Is Applicable: ${isApplicable ? "✅ YES" : "❌ NO"}');
                  if (!isApplicable) {
                    print('      Need: ₹${remainingAmount.toStringAsFixed(0)} more');
                  }
                }
              }
            }

            // Skip if should not show
            if (!shouldShowCoupon) {
              print('   🚫 HIDDEN FROM LIST\n');
              continue;
            }

            // Store calculated data
            couponData['applicableVendorIds'] = applicableVendorIds;
            couponData['remainingAmount'] = remainingAmount;
            couponData['isApplicable'] = isApplicable;
            couponData['relevantAmount'] = relevantAmount;

            // Sort into lists
            if (isApplicable) {
              print('   ✅ APPLICABLE\n');
              applicableCoupons.add(couponData);
            } else {
              print('   📝 NOT APPLICABLE\n');
              notApplicableCoupons.add(couponData);
            }
          }

          final allCoupons = [...applicableCoupons, ...notApplicableCoupons];

          print('╔═══════════════════════════════════════╗');
          print('║         FINAL RESULTS                 ║');
          print('╠═══════════════════════════════════════╣');
          print('║  ✅ Applicable: ${applicableCoupons.length.toString().padLeft(2)}                    ║');
          print('║  ⚠️  Not Applicable: ${notApplicableCoupons.length.toString().padLeft(2)}                ║');
          print('║  📊 Total Shown: ${allCoupons.length.toString().padLeft(2)}                    ║');
          print('╚═══════════════════════════════════════╝\n');

          if (allCoupons.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allCoupons.length,
            itemBuilder: (context, index) {
              final coupon = allCoupons[index];
              return _CouponCard(
                coupon: coupon,
                remainingAmount: coupon['remainingAmount'] as double,
                isApplicable: coupon['isApplicable'] as bool,
                vendorNames: vendorNames,
                applicableVendorIds: coupon['applicableVendorIds'] as List<String>,
                isWholeApp: coupon['isWholeApp'] ?? true,
                vendorAmounts: vendorAmounts,
                onApply: () {
                  if (coupon['isApplicable'] as bool) {
                    Clipboard.setData(
                      ClipboardData(text: coupon['couponCode'] as String),
                    );
                    Navigator.pop(context, coupon);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // FIXED: Improved vendor matching logic
  List<String> _findMatchingVendors({
    required List<String> cartVendorIds,
    required List<String> couponVendorIds,
    required Map<String, String> vendorNames,
  }) {
    final matchedIds = <String>[];

    for (var cartId in cartVendorIds) {
      // Normalize: trim whitespace
      final normalizedCartId = cartId.trim();

      for (var couponId in couponVendorIds) {
        final normalizedCouponId = couponId.trim();

        // Direct ID match (case-sensitive for Firebase doc IDs)
        if (normalizedCartId == normalizedCouponId) {
          matchedIds.add(cartId); // Keep original format
          print('         ✅ MATCH: "$cartId" == "$couponId"');
          break;
        }
      }
    }

    return matchedIds;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No coupons available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for exciting offers',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final double remainingAmount;
  final bool isApplicable;
  final Map<String, String> vendorNames;
  final List<String> applicableVendorIds;
  final bool isWholeApp;
  final Map<String, double> vendorAmounts;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.remainingAmount,
    required this.isApplicable,
    required this.vendorNames,
    required this.applicableVendorIds,
    required this.isWholeApp,
    required this.vendorAmounts,
    required this.onApply,
  });

  String _buildAddMoreMessage() {
    if (isApplicable || applicableVendorIds.isEmpty) return '';

    final minAmount = (coupon['minAmount'] ?? 0).toDouble();

    if (isWholeApp) {
      return 'Add ₹${remainingAmount.toStringAsFixed(0)} more to unlock';
    }

    // Vendor-specific
    final totalFromVendors = applicableVendorIds.fold(
      0.0,
          (sum, id) => sum + (vendorAmounts[id] ?? 0),
    );
    final shortage = minAmount - totalFromVendors;

    if (shortage <= 0) return '';

    if (applicableVendorIds.length == 1) {
      final vendorName = vendorNames[applicableVendorIds[0]] ?? 'this restaurant';
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $vendorName';
    } else if (applicableVendorIds.length == 2) {
      final name1 = vendorNames[applicableVendorIds[0]] ?? 'Restaurant 1';
      final name2 = vendorNames[applicableVendorIds[1]] ?? 'Restaurant 2';
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $name1 or $name2';
    } else {
      final name1 = vendorNames[applicableVendorIds[0]] ?? 'Restaurant';
      final others = applicableVendorIds.length - 1;
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $name1 or $others others';
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponType = coupon['couponType'] ?? 'discount';
    return couponType == 'freebie'
        ? _buildFreebieCard(context)
        : _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final couponType = coupon['couponType'] ?? 'discount';
    final couponCode = coupon['couponCode'] ?? '';
    final description = coupon['description'] ?? '';

    String titleText;
    IconData iconData;
    Color iconColor;

    if (couponType == 'discount') {
      final discountAmount = (coupon['discountAmount'] ?? 0).toDouble();
      titleText = 'FLAT ₹${discountAmount.toInt()} OFF';
      iconData = Icons.local_offer;
      iconColor = Colors.green;
    } else {
      titleText = 'FREE DELIVERY';
      iconData = Icons.delivery_dining;
      iconColor = Colors.blue;
    }

    final addMoreMessage = _buildAddMoreMessage();

    return GestureDetector(
      onTap: isApplicable ? onApply : null,
      child: Opacity(
        opacity: isApplicable ? 1.0 : 0.7,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isApplicable ? Colors.green.shade300 : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isApplicable
                ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isApplicable
                      ? iconColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: isApplicable ? iconColor : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isApplicable
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isApplicable
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        couponCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isApplicable
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isApplicable ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (!isWholeApp && applicableVendorIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store, size: 14, color: Colors.purple.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Valid for: ${applicableVendorIds.map((id) => vendorNames[id] ?? 'Restaurant').join(", ")}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!isApplicable && addMoreMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                addMoreMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isApplicable ? Colors.green.shade600 : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isApplicable
                    ? Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreebieCard(BuildContext context) {
    final freebieName = coupon['freebieName'] ?? 'FREE ITEM';
    final freebieImageUrl = coupon['freebieImageUrl'];
    final couponCode = coupon['couponCode'] ?? '';
    final description = coupon['description'] ?? '';
    final addMoreMessage = _buildAddMoreMessage();

    return GestureDetector(
      onTap: isApplicable ? onApply : null,
      child: Opacity(
        opacity: isApplicable ? 1.0 : 0.7,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isApplicable ? Colors.orange.shade300 : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isApplicable
                ? [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: freebieImageUrl != null && freebieImageUrl.toString().isNotEmpty
                    ? Image.network(
                  freebieImageUrl,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: Colors.orange.shade100,
                    child: const Icon(Icons.redeem, color: Colors.orange, size: 40),
                  ),
                )
                    : Container(
                  width: 100,
                  height: 140,
                  color: Colors.orange.shade100,
                  child: const Icon(Icons.redeem, color: Colors.orange, size: 40),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isApplicable ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isApplicable ? Colors.orange.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          couponCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isApplicable ? Colors.orange.shade800 : Colors.grey.shade700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        freebieName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!isWholeApp && applicableVendorIds.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, size: 12, color: Colors.purple.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Valid: ${applicableVendorIds.map((id) => vendorNames[id]).join(", ")}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isApplicable && addMoreMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  addMoreMessage,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isApplicable ? Colors.orange.shade600 : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isApplicable
                      ? Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
