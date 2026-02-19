import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import 'bottom_navigation.dart';
import 'top_bar.dart';
import 'vendor_items_page.dart';
import 'cart_screen.dart';
import 'help_screen.dart';
import 'promotional.dart';
import 'settings_screen.dart';
import 'location_picker_page.dart';

// ─── Service Zone Model ───────────────────────────────────────────────────────

class _ServiceZone {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  const _ServiceZone({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });
}

const List<_ServiceZone> kServiceZones = [
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.476388,
    lng: 78.390350,
    radiusMeters: 805.83,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.485210,
    lng: 78.376959,
    radiusMeters: 941.10,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.490998,
    lng: 78.393568,
    radiusMeters: 1020.00,
  ),
  _ServiceZone(
    name: 'KPHB - Kukatpally Housing Board Colony',
    lat: 17.493208,
    lng: 78.383281,
    radiusMeters: 750.00,
  ),
  _ServiceZone(
    name: 'Madhapur',
    lat: 17.446960,
    lng: 78.391101,
    radiusMeters: 1225.23,
  ),
  _ServiceZone(
    name: 'Nizampet',
    lat: 17.509248,
    lng: 78.373744,
    radiusMeters: 1471.04,
  ),
  _ServiceZone(
    name: 'Pragathi Nagar',
    lat: 17.522838,
    lng: 78.396081,
    radiusMeters: 1380.00,
  ),
  _ServiceZone(
    name: 'Addagutta',
    lat: 17.503804,
    lng: 78.396080,
    radiusMeters: 1029.53,
  ),
  _ServiceZone(
    name: 'Gajularamaram',
    lat: 17.536753,
    lng: 78.396639,
    radiusMeters: 491.73,
  ),
];

/// Returns matched zone name or null if outside all zones
String? getMatchedZone(double lat, double lng) {
  for (final zone in kServiceZones) {
    final dist = _haversineDistance(lat, lng, zone.lat, zone.lng);
    if (dist <= zone.radiusMeters) return zone.name;
  }
  return null;
}

double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _deg2rad(double deg) => deg * pi / 180;

// ─── KEY FIX: Universal vendor location matcher ───────────────────────────────
// Reads BOTH the "address" string field (comma-separated zones)
// AND the "locations" array field (if it exists), so either format works.

bool _vendorServesZone(Map<String, dynamic> data, String zone) {
  final zoneLower = zone.toLowerCase().trim();

  // ── Try "address" field (comma-separated string) ──
  final addressField = data['address'];
  if (addressField is String && addressField.isNotEmpty) {
    final parts = addressField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p))) {
      return true;
    }
  }

  // ── Try "locations" field (List or comma-string) ──
  final locationsField = data['locations'];
  if (locationsField is List) {
    final locs = locationsField.map((e) => e.toString().trim().toLowerCase());
    if (locs.any((l) => l.contains(zoneLower) || zoneLower.contains(l))) {
      return true;
    }
  } else if (locationsField is String && locationsField.isNotEmpty) {
    final parts = locationsField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p))) {
      return true;
    }
  }

  return false;
}

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  final String? phoneNumber;
  const HomePage({super.key, this.phoneNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  SavedLocation? _activeAddress;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        phoneNumber: widget.phoneNumber,
        activeAddress: _activeAddress,
        onAddressChanged: (loc) => setState(() => _activeAddress = loc),
      ),
      CartScreen(
        deliveryAddress: _activeAddress,
        onBackToHome: () => setState(() => _currentIndex = 0),
      ),
      const HelpScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: BandiwalaBottomNavigation(
          currentIndex: _currentIndex,
          onItemSelected: (idx) => setState(() => _currentIndex = idx),
        ),
      ),
    );
  }
}

// ─── HomeTab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final String? phoneNumber;
  final SavedLocation? activeAddress;
  final Function(SavedLocation) onAddressChanged;

  const _HomeTab({
    this.phoneNumber,
    this.activeAddress,
    required this.onAddressChanged,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchQuery = '';
  List<VendorSearchResult> _searchResults = [];
  bool _isLoadingSearch = false;

  double? _userLat;
  double? _userLng;
  String? _matchedZone;
  bool _locationChecked = false;
  bool _isOutsideAllZones = false;

  @override
  void initState() {
    super.initState();
    _resolveUserLocation();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeAddress != widget.activeAddress) {
      _resolveUserLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Resolve location ──────────────────────────────────────────────────────

  Future<void> _resolveUserLocation() async {
    double? lat;
    double? lng;

    if (widget.activeAddress != null) {
      lat = widget.activeAddress!.latitude;
      lng = widget.activeAddress!.longitude;
    } else {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _setNoLocation();
          return;
        }
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          _setNoLocation();
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        debugPrint('GPS error: $e');
        _setNoLocation();
        return;
      }
    }

    final zone = getMatchedZone(lat!, lng!);

    if (mounted) {
      setState(() {
        _userLat = lat;
        _userLng = lng;
        _matchedZone = zone;
        _locationChecked = true;
        _isOutsideAllZones = zone == null;
      });
    }

    if (zone == null) {
      _logUnavailableLocation(lat, lng);
    }
  }

  void _setNoLocation() {
    if (mounted) {
      setState(() {
        _locationChecked = true;
        _isOutsideAllZones = false;
      });
    }
  }

  Future<void> _logUnavailableLocation(double lat, double lng) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('logs').add({
        'mobile': user?.phoneNumber ?? widget.phoneNumber ?? 'unknown',
        'uid': user?.uid ?? 'unknown',
        'latitude': lat,
        'longitude': lng,
        'timestamp': FieldValue.serverTimestamp(),
        'reason': 'location_not_in_service_zone',
      });
    } catch (e) {
      debugPrint('Log error: $e');
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim().toLowerCase();
      _isLoadingSearch = true;
    });

    try {
      final results = await _performSearch(_searchQuery);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingSearch = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isLoadingSearch = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      _isLoadingSearch = false;
    });
  }

  Future<List<VendorSearchResult>> _performSearch(String query) async {
    final searchTerms = query
        .toLowerCase()
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();

    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .get();

    Map<String, VendorSearchResult> vendorsMap = {};

    for (var doc in itemsSnapshot.docs) {
      final data = doc.data();

      // ── Zone filter using the universal matcher ──────────────────────────
      if (_matchedZone != null) {
        if (!_vendorServesZone(data, _matchedZone!)) continue;
      }

      final vendorId = data['id'] ?? doc.id;
      final vendorName = (data['name'] ?? '').toString().toLowerCase();
      final vendorCategory = (data['category'] ?? '').toString().toLowerCase();

      bool vendorMatches = searchTerms.any(
        (term) => vendorName.contains(term) || vendorCategory.contains(term),
      );

      final vendorItemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .doc(doc.id)
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> matchingItems = [];

      for (var itemDoc in vendorItemsSnapshot.docs) {
        final itemData = itemDoc.data();
        final itemName = (itemData['name'] ?? '').toString().toLowerCase();
        final itemCategory = (itemData['category'] ?? '')
            .toString()
            .toLowerCase();
        final itemDescription = (itemData['description'] ?? '')
            .toString()
            .toLowerCase();
        final itemTags =
            (itemData['tags'] as List<dynamic>?)
                ?.map((t) => t.toString().toLowerCase())
                .toList() ??
            [];

        bool itemMatches = searchTerms.any(
          (term) =>
              itemName.contains(term) ||
              itemCategory.contains(term) ||
              itemDescription.contains(term) ||
              itemTags.any((tag) => tag.contains(term)),
        );

        if (itemMatches) {
          matchingItems.add({
            'id': itemDoc.id,
            'name': itemData['name'],
            'price': itemData['price'],
            'imageUrl': itemData['imageUrl'],
            'category': itemData['category'],
            'isVeg': itemData['isVeg'] ?? true,
          });
        }
      }

      if (vendorMatches || matchingItems.isNotEmpty) {
        vendorsMap[vendorId] = VendorSearchResult(
          vendorId: vendorId,
          vendorName: data['name'] ?? 'Unknown Vendor',
          vendorCategory: data['category'] ?? '',
          vendorImageUrl: data['imageUrl'] ?? '',
          address: data['address'] ?? '',
          rating: (data['rating'] ?? 4.2).toDouble(),
          isAvailable: data['isAvailable'] ?? true,
          matchingItems: matchingItems,
          isVendorMatch: vendorMatches,
        );
      }
    }

    return vendorsMap.values.toList();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _isSearching) _clearSearch();
      },
      child: SafeArea(
        child: Column(
          children: [
            BandiwalaTopBar(
              phoneNumber: widget.phoneNumber,
              searchController: _searchController,
              onLocationError: (_) {},
              onSearchSubmitted: _handleSearch,
              onSearchCleared: _clearSearch,
              onAddressChanged: (loc) {
                widget.onAddressChanged(loc);
                Future.delayed(
                  const Duration(milliseconds: 100),
                  _resolveUserLocation,
                );
              },
            ),
            Expanded(
              child: !_locationChecked
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: bandiwalaYellow,
                        strokeWidth: 2,
                      ),
                    )
                  : _isOutsideAllZones
                  ? _buildOutOfServiceView()
                  : _isSearching
                  ? _buildSearchResults()
                  : _buildNormalView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Out of Service ────────────────────────────────────────────────────────

  Widget _buildOutOfServiceView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 64,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'We\'re not here yet!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bandiwala hasn\'t launched in your area yet. We\'re expanding fast and will be there soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Currently serving: KPHB Kukatpally, Madhapur, Nizampet, Pragathi Nagar, Addagutta & Gajularamaram',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resolveUserLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: bandiwalaYellow,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push<SavedLocation>(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPickerPage()),
                );
                if (result != null) {
                  widget.onAddressChanged(result);
                  _resolveUserLocation();
                }
              },
              icon: const Icon(
                Icons.edit_location_alt_outlined,
                color: bandiwalaYellow,
              ),
              label: const Text(
                'Change Address',
                style: TextStyle(color: bandiwalaYellow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Results ────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_isLoadingSearch) {
      return const Center(
        child: CircularProgressIndicator(
          color: bandiwalaYellow,
          strokeWidth: 3,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No results found for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for different items or vendors',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Found ${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        ..._searchResults.map(
          (result) =>
              _SearchResultCard(result: result, searchQuery: _searchQuery),
        ),
      ],
    );
  }

  // ─── Normal View ───────────────────────────────────────────────────────────

  Widget _buildNormalView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        const SizedBox(height: 12),
        PromotionalBanner(
          onCategorySelected: (category) {
            if (category.isEmpty) {
              _clearSearch();
            } else {
              _searchController.text = category;
              _handleSearch(category);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Vendors near you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (_matchedZone != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'in $_matchedZone',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _VendorsList(matchedZone: _matchedZone),
      ],
    );
  }
}

// ─── Search Result Card ───────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final VendorSearchResult result;
  final String searchQuery;

  const _SearchResultCard({required this.result, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _VendorCard(
        vendorId: result.vendorId,
        name: result.vendorName,
        imageUrl: result.vendorImageUrl,
        address: result.address,
        category: result.vendorCategory,
        rating: result.rating,
        isAvailable: result.isAvailable,
        matchingItems: result.matchingItems,
      ),
    );
  }
}

// ─── Search Result Model ──────────────────────────────────────────────────────

class VendorSearchResult {
  final String vendorId;
  final String vendorName;
  final String vendorCategory;
  final String vendorImageUrl;
  final String address;
  final double rating;
  final bool isAvailable;
  final List<Map<String, dynamic>> matchingItems;
  final bool isVendorMatch;

  VendorSearchResult({
    required this.vendorId,
    required this.vendorName,
    required this.vendorCategory,
    required this.vendorImageUrl,
    required this.address,
    required this.rating,
    required this.isAvailable,
    required this.matchingItems,
    required this.isVendorMatch,
  });
}

// ─── Vendors List ─────────────────────────────────────────────────────────────

class _VendorsList extends StatelessWidget {
  final String? matchedZone;
  const _VendorsList({this.matchedZone});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                color: Color(0xFFFFC107),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final allDocs = snapshot.data!.docs;

        // ── Filter using universal matcher ─────────────────────────────────
        final docs = matchedZone == null
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _vendorServesZone(data, matchedZone!);
              }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    matchedZone != null
                        ? 'No vendors available in $matchedZone right now'
                        : 'No vendors available right now',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VendorCard(
                vendorId: data['id'] ?? doc.id,
                name: data['name'] ?? 'Vendor',
                imageUrl: data['imageUrl'] ?? '',
                address: data['address'] ?? '',
                category: data['category'] ?? '',
                rating: (data['rating'] ?? 4.2).toDouble(),
                isAvailable: data['isAvailable'] ?? true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Wishlist ─────────────────────────────────────────────────────────────────

class WishlistVendor {
  final String vendorId;
  final String name;
  final String imageUrl;
  final String address;
  final String category;
  final double rating;

  WishlistVendor({
    required this.vendorId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.category,
    required this.rating,
  });

  Map<String, dynamic> toJson() => {
    'vendorId': vendorId,
    'name': name,
    'imageUrl': imageUrl,
    'address': address,
    'category': category,
    'rating': rating,
  };

  factory WishlistVendor.fromJson(Map<String, dynamic> json) => WishlistVendor(
    vendorId: json['vendorId'],
    name: json['name'],
    imageUrl: json['imageUrl'],
    address: json['address'],
    category: json['category'],
    rating: (json['rating'] as num).toDouble(),
  );
}

class WishlistManager {
  static const String _key = 'wishlist_vendors';

  static Future<List<WishlistVendor>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList(_key) ?? [];
    return wishlistJson
        .map((json) => WishlistVendor.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<bool> isInWishlist(String vendorId) async {
    final wishlist = await getWishlist();
    return wishlist.any((v) => v.vendorId == vendorId);
  }

  static Future<void> addToWishlist(WishlistVendor vendor) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = await getWishlist();
    if (wishlist.any((v) => v.vendorId == vendor.vendorId)) return;
    wishlist.insert(0, vendor);
    await prefs.setStringList(
      _key,
      wishlist.map((v) => jsonEncode(v.toJson())).toList(),
    );
  }

  static Future<void> removeFromWishlist(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = await getWishlist();
    wishlist.removeWhere((v) => v.vendorId == vendorId);
    await prefs.setStringList(
      _key,
      wishlist.map((v) => jsonEncode(v.toJson())).toList(),
    );
  }

  static Future<void> toggleWishlist(WishlistVendor vendor) async {
    if (await isInWishlist(vendor.vendorId)) {
      await removeFromWishlist(vendor.vendorId);
    } else {
      await addToWishlist(vendor);
    }
  }
}

// ─── Vendor Card ──────────────────────────────────────────────────────────────

class _VendorCard extends StatefulWidget {
  final String vendorId;
  final String name;
  final String imageUrl;
  final String address;
  final String category;
  final double rating;
  final bool isAvailable;
  final List<Map<String, dynamic>>? matchingItems;

  const _VendorCard({
    required this.vendorId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.category,
    required this.rating,
    required this.isAvailable,
    this.matchingItems,
  });

  @override
  State<_VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<_VendorCard> {
  bool _isInWishlist = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final isInList = await WishlistManager.isInWishlist(widget.vendorId);
    if (mounted) setState(() => _isInWishlist = isInList);
  }

  Future<void> _toggleWishlist() async {
    setState(() => _isLoading = true);
    final vendor = WishlistVendor(
      vendorId: widget.vendorId,
      name: widget.name,
      imageUrl: widget.imageUrl,
      address: widget.address,
      category: widget.category,
      rating: widget.rating,
    );
    await WishlistManager.toggleWishlist(vendor);
    final isInList = await WishlistManager.isInWishlist(widget.vendorId);
    if (mounted) {
      setState(() {
        _isInWishlist = isInList;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInList
                ? '${widget.name} added to wishlist'
                : '${widget.name} removed from wishlist',
          ),
          backgroundColor: isInList ? Colors.green : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isAvailable,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.isAvailable
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VendorItemsPage(
                        vendorId: widget.vendorId,
                        vendorName: widget.name,
                      ),
                    ),
                  )
                : null,
            child: Card(
              elevation: 1.5,
              color: Colors.white.withOpacity(0.94),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.store)),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.store)),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _isLoading ? null : _toggleWishlist,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : Icon(
                                      _isInWishlist
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: _isInWishlist
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (widget.matchingItems != null &&
                            widget.matchingItems!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFC107).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Matching Items (${widget.matchingItems!.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...widget.matchingItems!
                                    .take(2)
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item['isVeg'] == true
                                                  ? Icons.circle
                                                  : Icons.change_history,
                                              size: 8,
                                              color: item['isVeg'] == true
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '₹${item['price']}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                if (widget.matchingItems!.length > 2)
                                  Text(
                                    '+${widget.matchingItems!.length - 2} more',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isAvailable)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                child: const Text(
                  'Currently Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
