import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/scrolling_announcement.dart';
import '../widgets/promotional_banner.dart';
import '../widgets/recommended_vendors.dart';
import '../widgets/food_category_carousel.dart';
import '../providers/active_address_provider.dart';
import '../providers/items_provider.dart';
import '../providers/vendors_provider.dart';
import '../widgets/vendor_card.dart';
import '../widgets/vendors_list.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = '';
  final ScrollController _scrollController = ScrollController();
  bool _marqueeHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkName());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final hidden = _scrollController.offset > 20;
    if (hidden != _marqueeHidden) {
      setState(() => _marqueeHidden = hidden);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Name prompt on first login ───────────────────────────────────────────

  void _checkName() {
    final appUser = ref.read(userProvider).valueOrNull;
    if (appUser == null) return;
    if (appUser.name.isEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showNamePrompt();
      });
    }
  }

  void _showNamePrompt() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.waving_hand_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                "What's your name?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(userProvider.notifier).updateName(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeAddress = ref.watch(activeAddressProvider);

    return SafeArea(
      child: Column(
        children: [
          TopBar(
            activeAddress: activeAddress,
            onAddressChanged: (loc) =>
                ref.read(activeAddressProvider.notifier).setAddress(loc),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: SizedBox(
              height: _marqueeHidden ? 0 : null,
              child: ClipRect(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _marqueeHidden ? 0.0 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const ScrollingAnnouncement(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _HomeContent(
              scrollController: _scrollController,
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) =>
                  setState(() => _selectedCategory = cat),
              onCategoryClear: () => setState(() => _selectedCategory = ''),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home content (single scrollable view) ───────────────────────────────────

class _HomeContent extends ConsumerWidget {
  final String selectedCategory;
  final void Function(String) onCategorySelected;
  final VoidCallback onCategoryClear;
  final ScrollController scrollController;

  const _HomeContent({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onCategoryClear,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCategory = selectedCategory.isNotEmpty;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // ── Always visible ────────────────────────────────────────────────
        const SizedBox(height: 12),
        const PromotionalBanner(),
        const SizedBox(height: 24),
        const RecommendedVendorsStrip(),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FoodCategoryCarousel(onCategorySelected: onCategorySelected),
        ),
        const SizedBox(height: 20),

        // ── Vendor section — filtered or full ─────────────────────────────
        if (hasCategory) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Category:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(selectedCategory),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: onCategoryClear,
                  backgroundColor: AppColors.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _CategoryResults(category: selectedCategory, ref: ref),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Vendors near you',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _LiveBadge(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VendorsList(matchedZone: null),
        ],
      ],
    );
  }
}

// ─── Category results (inline widget) ────────────────────────────────────────

class _CategoryResults extends StatelessWidget {
  final String category;
  final WidgetRef ref;

  const _CategoryResults({required this.category, required this.ref});

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allAvailableItemsProvider);
    final vendors = ref.watch(vendorsStreamProvider).valueOrNull ?? [];
    final vendorMap = {for (final v in vendors) v.id: v};

    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: VendorsListSkeleton(),
      ),
      error: (_, __) => const Center(child: Text('Failed to load items')),
      data: (items) {
        final cat = category.toLowerCase();
        final Map<String, List<dynamic>> byVendor = {};
        for (final item in items) {
          if (item.vendorId.isEmpty) continue;
          if (!item.category.toLowerCase().contains(cat)) continue;
          byVendor.putIfAbsent(item.vendorId, () => []).add(item);
        }

        if (byVendor.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No items found in "$category"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final entry in byVendor.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VendorCard(
                  vendorId: entry.key,
                  name: vendorMap[entry.key]?.name ?? entry.key,
                  imageUrl: vendorMap[entry.key]?.imageUrl ?? '',
                  address: vendorMap[entry.key]?.address ?? '',
                  category: vendorMap[entry.key]?.category ?? '',
                  rating: vendorMap[entry.key]?.rating ?? 0,
                  isAvailable: vendorMap[entry.key]?.isAvailable ?? true,
                  matchingItems: entry.value
                      .map(
                        (item) => {
                          'id': item.id,
                          'name': item.name,
                          'price': item.price,
                          'imageUrl': item.imageUrl,
                          'isVeg': item.isVeg,
                        },
                      )
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Live badge ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> {
  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(child: _LiveBadgeBody());
  }
}

class _LiveBadgeBody extends StatefulWidget {
  const _LiveBadgeBody();
  @override
  State<_LiveBadgeBody> createState() => _LiveBadgeBodyState();
}

class _LiveBadgeBodyState extends State<_LiveBadgeBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.green.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
