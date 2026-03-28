import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../providers/food_categories_provider.dart';
import 'skeletons.dart';

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
          .where((c) => c.name.toLowerCase() != 'all')
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
          _categories = items;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('FoodCategoryCarousel error: $e');
      if (mounted) {
        setState(() {
          _categories = [];
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
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Builder(
          builder: (context) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final double carouselHeight = screenHeight * 0.14; // Responsive height

            return SizedBox(
              height: carouselHeight.clamp(110, 130), // Minimum and maximum safe heights
              child: _isLoading
                  ? const CategoryCarouselSkeleton()
                  : _categories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
            );
          }
        ),
      ],
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHighest,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
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
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant,
                        size: 28,
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl.trim(),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: cs.surfaceContainerHighest),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.radio_button_checked, // Changed icon to be more subtle if image fails
                        size: 28,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
