import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../providers/food_categories_provider.dart';
import 'promotional_banner.dart' show kBandiwalaYellow;

// ─── FoodCategoryCarousel ─────────────────────────────────────────────────────

class FoodCategoryCarousel extends StatefulWidget {
  final void Function(String) onCategorySelected;

  const FoodCategoryCarousel({super.key, required this.onCategorySelected});

  @override
  State<FoodCategoryCarousel> createState() => _FoodCategoryCarouselState();
}

class _FoodCategoryCarouselState extends State<FoodCategoryCarousel>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  List<_CategoryItem> _categories = [];
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_hasLoaded) return;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final categories = await container.read(foodCategoriesProvider.future);

      final items = categories
          .map(
            (c) => _CategoryItem(
              name: c.name,
              imageUrl: c.imageUrl,
              isLocal: false,
            ),
          )
          .toList();
      items.shuffle(Random());

      if (mounted) {
        setState(() {
          _categories = [
            _CategoryItem(
              name: 'All',
              imageUrl: 'assets/images/Bajji pakoda.png',
              isLocal: true,
            ),
            ...items,
          ];
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [
            _CategoryItem(
              name: 'All',
              imageUrl: 'assets/images/Bajji pakoda.png',
              isLocal: true,
            ),
          ];
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedIndex = index);

    const double itemWidth = 75.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double target =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }

    final name = _categories[index].name;
    widget.onCategorySelected(name == 'All' ? '' : name);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's on your mind?",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: _isLoading
              ? _buildShimmer()
              : _categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _onCategoryTap(index),
                    child: _CategoryCard(
                      item: _categories[index],
                      isSelected: index == _selectedIndex,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              height: 10,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal model ───────────────────────────────────────────────────────────

class _CategoryItem {
  final String name, imageUrl;
  final bool isLocal;
  const _CategoryItem({
    required this.name,
    required this.imageUrl,
    required this.isLocal,
  });
}

// ─── _CategoryCard ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;
  final bool isSelected;

  const _CategoryCard({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: ClipOval(
              child: item.isLocal
                  ? Image.asset(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 28,
                        color: Colors.grey,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      memCacheHeight: 128,
                      maxWidthDiskCache: 128,
                      maxHeightDiskCache: 128,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBandiwalaYellow,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 28,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Column(
            children: [
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSelected ? 11.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 28 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: kBandiwalaYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
