import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import '../models/item.dart';
import '../core/theme/theme.dart';
import '../core/navigation/app_page_route.dart';
import '../widgets/item_customization_sheet.dart';
import '../widgets/skeletons.dart';
import 'vendor_items_page.dart';

// ─── Search result model ──────────────────────────────────────────────────────

class _VendorResult {
  final String vendorId, vendorName, vendorCategory, vendorImageUrl, address;
  final double rating;
  final bool isAvailable;
  final List<Map<String, dynamic>> matchingItems;

  _VendorResult({
    required this.vendorId,
    required this.vendorName,
    required this.vendorCategory,
    required this.vendorImageUrl,
    required this.address,
    required this.rating,
    required this.isAvailable,
    required this.matchingItems,
  });
}

// ─── SearchResultsPage ────────────────────────────────────────────────────────

class SearchResultsPage extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late TextEditingController _controller;
  bool _isLoading = true;
  List<_VendorResult> _results = [];
  late String _currentQuery;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
    _controller = TextEditingController(text: widget.query);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runSearch(_currentQuery),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
      _results = [];
    });

    try {
      final terms = _currentQuery
          .toLowerCase()
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();
      final items = ref.read(allAvailableItemsProvider).valueOrNull ?? [];
      final vendors = ref.read(vendorsStreamProvider).valueOrNull ?? [];
      final vendorMap = {for (final v in vendors) v.id: v};
      final Map<String, _VendorResult> map = {};

      for (final item in items) {
        if (item.vendorId.isEmpty) continue;
        final n = item.name.toLowerCase();
        final c = item.category.toLowerCase();
        final desc = item.description.toLowerCase();
        final tags = item.tags.map((t) => t.toLowerCase()).toList();
        final hit = terms.any(
          (t) =>
              n.contains(t) ||
              c.contains(t) ||
              desc.contains(t) ||
              tags.any((tag) => tag.contains(t)),
        );
        if (!hit) continue;
        final vendor = vendorMap[item.vendorId];
        if (vendor == null) continue;
        map.putIfAbsent(
          item.vendorId,
          () => _VendorResult(
            vendorId: vendor.id,
            vendorName: vendor.name,
            vendorCategory: vendor.category,
            vendorImageUrl: vendor.imageUrl,
            address: vendor.address,
            rating: vendor.rating,
            isAvailable: vendor.isAvailable,
            matchingItems: [],
          ),
        );
        map[item.vendorId]!.matchingItems.add({
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'description': item.description,
          'isVeg': item.isVeg,
          'item': item,
        });
      }

      for (final vendor in vendors) {
        final vn = vendor.name.toLowerCase();
        final vc = vendor.category.toLowerCase();
        if (terms.any((t) => vn.contains(t) || vc.contains(t)) &&
            !map.containsKey(vendor.id)) {
          map[vendor.id] = _VendorResult(
            vendorId: vendor.id,
            vendorName: vendor.name,
            vendorCategory: vendor.category,
            vendorImageUrl: vendor.imageUrl,
            address: vendor.address,
            rating: vendor.rating,
            isAvailable: vendor.isAvailable,
            matchingItems: [],
          );
        }
      }

      if (mounted) {
        setState(() {
          _results = map.values.toList()
            ..sort(
              (a, b) =>
                  a.isAvailable == b.isAvailable ? 0 : (a.isAvailable ? -1 : 1),
            );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openVendor(_VendorResult vendor) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => VendorItemsPage(
          vendorId: vendor.vendorId,
          vendorName: vendor.vendorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (v) => _runSearch(v),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 15, color: cs.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Search for food, vendors...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (_, value, __) => value.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _controller.clear()),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SkeletonShimmer(
                child: Column(
                  children: List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No results for "$_currentQuery"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _results.length,
              itemBuilder: (_, i) =>
                  _VendorBlock(vendor: _results[i], onOpenVendor: _openVendor),
            ),
    );
  }
}

// ─── Vendor block ─────────────────────────────────────────────────────────────

class _VendorBlock extends StatelessWidget {
  final _VendorResult vendor;
  final void Function(_VendorResult) onOpenVendor;

  const _VendorBlock({required this.vendor, required this.onOpenVendor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onOpenVendor(vendor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark ? Border.all(color: cs.outlineVariant) : null,
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: _NetImg(
                          url: vendor.vendorImageUrl.isNotEmpty
                              ? vendor.vendorImageUrl
                              : (vendor.matchingItems.isNotEmpty
                                    ? vendor.matchingItems.first['imageUrl'] ??
                                          ''
                                    : ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vendor.vendorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Colors.green.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  vendor.vendorCategory.isNotEmpty
                                      ? vendor.vendorCategory
                                      : vendor.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onOpenVendor(vendor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.onSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (vendor.matchingItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vendor.matchingItems.length,
                itemBuilder: (ctx, idx) => _ItemCard(
                  vendor: vendor,
                  itemMap: vendor.matchingItems[idx],
                  onOpenVendor: onOpenVendor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final _VendorResult vendor;
  final Map<String, dynamic> itemMap;
  final void Function(_VendorResult) onOpenVendor;

  const _ItemCard({
    required this.vendor,
    required this.itemMap,
    required this.onOpenVendor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Item item = itemMap['item'];
    final bool isVeg = item.isVeg;
    final Color dot = isVeg ? Colors.green.shade500 : Colors.red.shade400;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: cs.outlineVariant) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: _NetImg(url: item.imageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    border: Border.all(color: dot, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
            child: Text(
              item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Text(
              '₹${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ItemCustomizationSheet(
                    item: item,
                    vendorId: vendor.vendorId,
                    vendorName: vendor.vendorName,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Network image helper ─────────────────────────────────────────────────────

class _NetImg extends StatelessWidget {
  final String url;
  const _NetImg({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (url.isEmpty) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.store_mall_directory_outlined,
          size: 22,
          color: cs.onSurfaceVariant,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
      errorWidget: (_, __, ___) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 22,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
