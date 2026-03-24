import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../screens/profile_page.dart';
import '../models/app_user.dart';
import '../screens/location_picker_page.dart';
import '../screens/vendor_items_page.dart';
import '../providers/cart_provider.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/theme.dart';
import '../core/navigation/app_page_route.dart';
import 'skeletons.dart';

const Color _kYellow = AppColors.primary;

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

// ─── TopBar ───────────────────────────────────────────────────────────────────
// Owns search entirely. Category filtering lives in home_page.

class TopBar extends ConsumerStatefulWidget {
  final Function(bool)? onLocationError;
  final Function(SavedAddress)? onAddressChanged;
  final SavedAddress? activeAddress;

  const TopBar({
    super.key,
    this.onLocationError,
    this.onAddressChanged,
    this.activeAddress,
  });

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> with WidgetsBindingObserver {
  static const double _minLat = 17.25, _maxLat = 17.55;
  static const double _minLng = 78.25, _maxLng = 78.65;

  // ── Location ───────────────────────────────────────────────────────────────
  SavedAddress? _activeAddress;
  String _displayLocation = 'Fetching location...';
  bool _isLocationError = false;
  StreamSubscription<Position>? _positionSub;

  // ── Speech ─────────────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // ── Wallet ─────────────────────────────────────────────────────────────────
  double _walletBalance = 0.0;

  // ── Search ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isTyping = false;
  bool _isSearchActive = false;
  bool _isLoadingSearch = false;
  List<_VendorResult> _searchResults = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _startLocationUpdates();
    _loadWalletBalance();
    _searchController.addListener(_onSearchTextChanged);
    if (widget.activeAddress != null) {
      _activeAddress = widget.activeAddress;
      _displayLocation =
          widget.activeAddress!.label ?? widget.activeAddress!.geolocation;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _speech.stop();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TopBar old) {
    super.didUpdateWidget(old);
    if (widget.activeAddress != old.activeAddress &&
        widget.activeAddress != null) {
      setState(() {
        _activeAddress = widget.activeAddress;
        _displayLocation =
            widget.activeAddress!.label ?? widget.activeAddress!.geolocation;
        _isLocationError = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startLocationUpdates();
      _loadWalletBalance();
    }
  }

  // ─── Wallet ────────────────────────────────────────────────────────────────

  Future<void> _loadWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(
          () => _walletBalance = prefs.getDouble('wallet_balance') ?? 0.0,
        );
      }
    } catch (_) {}
  }

  // ─── Speech ────────────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          if (status == 'done') {
            final text = _searchController.text.trim();
            if (text.isNotEmpty) _handleSearchSubmit();
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }
    if (!_speechEnabled || _isListening) return;
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            final words = result.recognizedWords;
            _searchController.text =
                words[0].toUpperCase() + words.substring(1);
            setState(() {});
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_IN',
        cancelOnError: true,
      );
      if (mounted) setState(() => _isListening = true);
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Future<void> _startLocationUpdates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocError('Enable location services');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        _setLocError('Location permissions denied');
        return;
      }
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _setLocError('Location permission needed');
          return;
        }
      }
      await _getCurrentLocationOnce();
      await _positionSub?.cancel();
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (pos) {
              if (_activeAddress == null) _updateLocationDisplay(pos);
            },
            onError: (_) {
              if (_activeAddress == null && mounted) {
                setState(() {
                  _displayLocation = 'Location error';
                  _isLocationError = true;
                });
              }
            },
          );
    } catch (_) {
      _setLocError('Unable to get location');
    }
  }

  void _setLocError(String msg) {
    if (_activeAddress == null && mounted) {
      setState(() {
        _displayLocation = msg;
        _isLocationError = true;
      });
    }
    widget.onLocationError?.call(true);
  }

  Future<void> _getCurrentLocationOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (_activeAddress == null) await _updateLocationDisplay(pos);
    } catch (_) {
      if (_activeAddress == null && mounted)
        setState(() => _displayLocation = 'Getting location...');
    }
  }

  Future<void> _updateLocationDisplay(Position pos) async {
    final ok = _isInHyderabad(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _displayLocation =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _isLocationError = !ok;
      });
    }
    widget.onLocationError?.call(!ok);
  }

  bool _isInHyderabad(double lat, double lng) =>
      lat >= _minLat && lat <= _maxLat && lng >= _minLng && lng <= _maxLng;

  Future<void> _showLocationPicker() async {
    final result = await Navigator.push<SavedAddress>(
      context,
      AppPageRoute(
        type: PageTransitionType.slideUp,
        builder: (_) => LocationPickerPage(
          activeAddress: _activeAddress,
          onLocationSelected: _onAddressSelected,
        ),
      ),
    );
    if (result != null) _onAddressSelected(result);
  }

  void _onAddressSelected(SavedAddress location) {
    if (!mounted) return;
    setState(() {
      _activeAddress = location;
      _displayLocation = location.label ?? location.geolocation;
      _isLocationError = false;
    });
    widget.onAddressChanged?.call(location);
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  void _onSearchTextChanged() {
    final text = _searchController.text.trim();
    if (mounted) setState(() => _isTyping = text.isNotEmpty);
  }

  void _handleSearchSubmit() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _runSearch(text);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {
        _isTyping = false;
        _isSearchActive = false;
        _isLoadingSearch = false;
        _searchResults = [];
        _searchQuery = '';
      });
    }
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearchActive = true;
      _isLoadingSearch = true;
      _searchQuery = query.trim().toLowerCase();
      _searchResults = [];
    });

    try {
      final terms = _searchQuery.split(' ').where((t) => t.isNotEmpty).toList();
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
          'rating': 4.2,
          'ratingCount': 0,
        });
      }

      // Also match vendors by name/category
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
          _searchResults = map.values.toList()
            ..sort(
              (a, b) =>
                  a.isAvailable == b.isAvailable ? 0 : (a.isAvailable ? -1 : 1),
            );
          _isLoadingSearch = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isLoadingSearch = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasAddr = _activeAddress != null;
    final topLabel = hasAddr ? _activeAddress!.shortLabel : 'Current Location';
    final displayText = hasAddr
        ? _activeAddress!.geolocation
        : (_isLocationError
              ? 'Currently serving only Hyderabad'
              : _displayLocation);
    final showError = !hasAddr && _isLocationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top row: location + wallet + profile ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                showError ? Icons.error_outline : Icons.location_on_outlined,
                color: showError ? Colors.red : _kYellow,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          topLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!hasAddr) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _kYellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              color: _kYellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _kYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _activeAddress!.shortLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: showError ? Colors.red : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    if (hasAddr &&
                        _activeAddress!.address != null &&
                        _activeAddress!.address!.isNotEmpty)
                      Text(
                        _activeAddress!.address!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasAddr)
                GestureDetector(
                  onTap: _showLocationPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _kYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _kYellow.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wallet feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.black87,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${_walletBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const ProfilePage()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isTyping || _isSearchActive)
                          ? _kYellow
                          : Colors.grey.shade300,
                      width: (_isTyping || _isSearchActive) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onSubmitted: (_) => _handleSearchSubmit(),
                          textInputAction: TextInputAction.search,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search street food, stalls...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (_isTyping || _isSearchActive)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: Icon(
                            Icons.clear,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _isTyping
                    ? _handleSearchSubmit
                    : (_isListening ? _stopListening : _startListening),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isTyping
                        ? Icons.search
                        : (_isListening ? Icons.stop : Icons.mic_none),
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Search results panel ──────────────────────────────────────────
        if (_isSearchActive) _buildResultsPanel(),
      ],
    );
  }

  // ─── Results panel ────────────────────────────────────────────────────────

  Widget _buildResultsPanel() {
    if (_isLoadingSearch) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SkeletonShimmer(
          child: Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'No results for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _buildVendorBlock(_searchResults[i]),
    );
  }

  Widget _buildVendorBlock(_VendorResult vendor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openVendor(vendor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
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
                        child: _netImg(
                          vendor.vendorImageUrl.isNotEmpty
                              ? vendor.vendorImageUrl
                              : (vendor.matchingItems.isNotEmpty
                                    ? vendor.matchingItems.first['imageUrl'] ??
                                          ''
                                    : ''),
                          fallback: const Icon(
                            Icons.store_mall_directory_outlined,
                            size: 22,
                          ),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
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
                                    color: Colors.grey.shade500,
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
                      onTap: () => _openVendor(vendor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                itemBuilder: (ctx, idx) =>
                    _buildItemCard(vendor, vendor.matchingItems[idx]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(_VendorResult vendor, Map<String, dynamic> item) {
    final bool isVeg = item['isVeg'] ?? true;
    final String imageUrl = item['imageUrl'] ?? '';
    final String name = item['name'] ?? 'Item';
    final String category = item['category'] ?? '';
    final double price = (item['price'] ?? 0).toDouble();
    final String itemId = item['id'] ?? '';
    final Color dot = isVeg ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openItemSheet(vendor, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: _netImg(
                  imageUrl,
                  fallback: const Icon(Icons.restaurant, size: 24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            border: Border.all(color: dot, width: 1.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: dot,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹ ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    _ItemCounter(
                      vendorId: vendor.vendorId,
                      vendorName: vendor.vendorName,
                      itemId: itemId,
                      itemName: name,
                      price: price,
                      isAvailable: vendor.isAvailable,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVendor(_VendorResult vendor) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => VendorItemsPage(
          vendorId: vendor.vendorId,
          vendorName: vendor.vendorName,
        ),
      ),
    );
  }

  void _openItemSheet(_VendorResult vendor, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailOverlay(
        vendorId: vendor.vendorId,
        vendorName: vendor.vendorName,
        itemId: item['id'] ?? '',
        name: item['name'] ?? '',
        imageUrl: item['imageUrl'] ?? '',
        category: item['category'] ?? '',
        description: item['description'] ?? '',
        isVeg: item['isVeg'] ?? true,
        price: (item['price'] ?? 0).toDouble(),
        rating: (item['rating'] ?? vendor.rating).toDouble(),
        ratingCount: (item['ratingCount'] ?? 0).toInt(),
        isAvailable: vendor.isAvailable,
      ),
    );
  }

  Widget _netImg(String url, {required Widget fallback}) {
    if (url.isEmpty)
      return Container(
        color: Colors.grey.shade200,
        child: Center(child: fallback),
      );
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      memCacheHeight: 200,
      placeholder: (_, __) => Container(
        color: Colors.grey.shade200,
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Center(child: fallback),
      ),
    );
  }
}

// ─── Item ADD / counter widget ────────────────────────────────────────────────

class _ItemCounter extends ConsumerWidget {
  final String vendorId, vendorName, itemId, itemName;
  final double price;
  final bool isAvailable;

  const _ItemCounter({
    required this.vendorId,
    required this.vendorName,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final vc = cart.cartByVendor[vendorId];
    final q =
        vc?.items
            .firstWhere(
              (i) => i.id == itemId,
              orElse: () => CartItem(id: '', name: '', price: 0, quantity: 0),
            )
            .quantity ??
        0;

    void add() => ref
        .read(cartProvider.notifier)
        .addItem(
          vendorId: vendorId,
          vendorName: vendorName,
          itemId: itemId,
          itemName: itemName,
          price: price,
        );
    void delta(int d) => ref
        .read(cartProvider.notifier)
        .updateQuantity(vendorId: vendorId, itemId: itemId, delta: d);

    if (!isAvailable) {
      return Container(
        height: 28,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'Unavailable',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
        ),
      );
    }

    if (q == 0) {
      return SizedBox(
        height: 28,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: add,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: Colors.black87, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'ADD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 28,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => delta(-1),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.remove, size: 14, color: Colors.black87),
            ),
          ),
          Text(
            '$q',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: () => delta(1),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.add, size: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
