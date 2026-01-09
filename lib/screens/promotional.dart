// ============ promotional.dart ============
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

const kBandiwalaYellow = Color(0xFFFFC107);

class PromotionalBanner extends StatefulWidget {
  const PromotionalBanner({super.key});

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<PromotionData> _promotions = [];
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    if (_hasLoaded) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .orderBy('order')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final activePromotions = snapshot.docs
            .where((doc) {
          final data = doc.data();
          return data['isActive'] == true;
        })
            .map((doc) => PromotionData.fromFirestore(doc))
            .toList();

        if (mounted) {
          setState(() {
            _promotions = activePromotions;
            _isLoading = false;
            _hasLoaded = true;
          });

          if (_promotions.isNotEmpty) {
            _startAutoScroll();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading promotions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients || _promotions.isEmpty) {
        return;
      }

      if (_currentPage < _promotions.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: kBandiwalaYellow,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Full-width banner
        SizedBox(
          height: 200,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              return _PromotionalImageCard(
                promotion: _promotions[index],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promotions.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? kBandiwalaYellow
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // ✅ Food Category Carousel
        const FoodCategoryCarousel(),
      ],
    );
  }
}

// ✅ Food Category Carousel Widget
class FoodCategoryCarousel extends StatefulWidget {
  const FoodCategoryCarousel({super.key});

  @override
  State<FoodCategoryCarousel> createState() => _FoodCategoryCarouselState();
}

class _FoodCategoryCarouselState extends State<FoodCategoryCarousel> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0; // 0 is "All" by default

  final List<FoodCategory> _categories = [
    FoodCategory(name: "All", image: "assets/images/Bajji pakoda.png"),
    FoodCategory(name: "Biriyani", image: "assets/images/Biriyani.png"),
    FoodCategory(name: "Starters", image: "assets/images/starters.png"),
    FoodCategory(name: "Chinese", image: "assets/images/Chinese.png"),
    FoodCategory(name: "Soups", image: "assets/images/Soups.png"),
    FoodCategory(name: "Sweets", image: "assets/images/Sweets.png"),
    FoodCategory(name: "Curries", image: "assets/images/Curries.png"),
    FoodCategory(name: "Nonveg Pakoda", image: "assets/images/Nonveg Pakoda.png"),
    FoodCategory(name: "Mixtures", image: "assets/images/Mixture.png"),
    FoodCategory(name: "Pulaos", image: "assets/images/Pulaos.png"),
    FoodCategory(name: "Panipuri", image: "assets/images/Panipuri.png"),
    FoodCategory(name: "Chat", image: "assets/images/Chat.png"),
    FoodCategory(name: "Pav Bhaji", image: "assets/images/Pav Bhaji.png"),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Scroll to center the selected item
    final double itemWidth = 75.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetScroll = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    _scrollController.animateTo(
      targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 0),
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            color: Colors.white,
            height: 120,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () => _onCategoryTap(index),
                  child: _FoodCategoryCard(
                    category: category,
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Food Category Model
class FoodCategory {
  final String name;
  final String image;

  FoodCategory({
    required this.name,
    required this.image,
  });
}

// ✅ Food Category Card - No shadow for unselected items
class _FoodCategoryCard extends StatelessWidget {
  final FoodCategory category;
  final bool isSelected;

  const _FoodCategoryCard({
    required this.category,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular image container
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              // ✅ Only show shadow when selected
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null, // ✅ No shadow for unselected items
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white,
                child: Image.asset(
                  category.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Category Name with animated underline
          Column(
            children: [
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  fontSize: isSelected ? 11.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              // Animated yellow underline
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 30 : 0,
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

// ✅ Promotion Data Model
class PromotionData {
  final String id;
  final String imageUrl;
  final int order;
  final bool isActive;

  PromotionData({
    required this.id,
    required this.imageUrl,
    required this.order,
    required this.isActive,
  });

  factory PromotionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionData(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}

// ✅ Promotional Image Card - Full width with contained image
class _PromotionalImageCard extends StatelessWidget {
  final PromotionData promotion;

  const _PromotionalImageCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: promotion.imageUrl.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: promotion.imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(
              color: kBandiwalaYellow,
              strokeWidth: 2.5,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Image not available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        memCacheWidth: 1200,
        memCacheHeight: 400,
        maxWidthDiskCache: 1200,
        maxHeightDiskCache: 400,
      )
          : Container(
        color: Colors.white,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
