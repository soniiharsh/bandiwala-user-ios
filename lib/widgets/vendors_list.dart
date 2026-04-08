import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vendors_provider.dart';
import 'vendor_card.dart';
import 'skeletons.dart';

class VendorsList extends ConsumerWidget {
  final String? matchedZone;
  const VendorsList({super.key, this.matchedZone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsStreamProvider);

    return vendorsAsync.when(
      loading: () => const VendorsListSkeleton(),
      error: (_, __) => const Center(child: Text('Something went wrong')),
      data: (vendors) {
        final filtered = matchedZone == null
            ? vendors
            : vendors.where((v) {
                final z = matchedZone!.toLowerCase().trim();
                final address = v.address.toLowerCase();
                return address
                    .split(',')
                    .any((p) => p.trim().contains(z) || z.contains(p.trim()));
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 60,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    matchedZone != null
                        ? 'No vendors in $matchedZone right now'
                        : 'No vendors available right now',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = [...filtered]
          ..sort((a, b) {
            if (a.isAvailable == b.isAvailable) return 0;
            return a.isAvailable ? -1 : 1;
          });

        return Container(
          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Column(
            children: sorted
                .map(
                  (v) => RepaintBoundary(
                    child: VendorCard(
                      vendorId: v.id,
                      name: v.name,
                      imageUrl: v.imageUrl,
                      address: v.address,
                      category: v.category,
                      rating: v.rating,
                      isAvailable: v.isAvailable,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
