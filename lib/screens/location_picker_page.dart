import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ─── Shared model ─────────────────────────────────────────────────────────────

class SavedLocation {
  final String address; // Human-readable area name (e.g. "KPHB, Hyderabad")
  final double latitude; // Full precision e.g. 17.476388123
  final double longitude; // Full precision e.g. 78.390350456
  final String? houseNo;
  final String? phone;
  final String? label;

  SavedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.houseNo,
    this.phone,
    this.label,
  });

  // ✅ lat/lng stored as full-precision doubles — never truncated
  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'houseNo': houseNo,
    'phone': phone,
    'label': label,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    address: json['address'] ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    houseNo: json['houseNo'],
    phone: json['phone'],
    label: json['label'],
  );

  bool isSameLocation(SavedLocation other) {
    const double threshold = 0.0005;
    return (latitude - other.latitude).abs() < threshold &&
        (longitude - other.longitude).abs() < threshold;
  }

  String get fullDisplay {
    final parts = <String>[];
    if (houseNo != null && houseNo!.isNotEmpty) parts.add(houseNo!);
    if (address.isNotEmpty) parts.add(address);
    return parts.join(', ');
  }

  // ✅ Shows area name + precise coordinates
  String get coordinatesDisplay =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get shortLabel => label ?? 'Other';
}

// ─── Autocomplete model ───────────────────────────────────────────────────────

class _PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;

  _PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });
}

// ─── LocationPickerPage ───────────────────────────────────────────────────────

class LocationPickerPage extends StatefulWidget {
  final Function(SavedLocation)? onLocationSelected;
  const LocationPickerPage({super.key, this.onLocationSelected});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  bool _showModeSelection = true;
  bool _isCurrentLocationMode = false;
  bool _isNewAddressMode = false;
  bool _isMapReady = false;

  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isOutsideHyderabad = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<SavedLocation> _savedLocations = [];
  bool _isFetchingLocation = false;
  String _selectedLabel = 'Home';
  String _fetchedAddress = '';

  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  final http.Client _httpClient = http.Client();

  static const double _minLat = 17.25;
  static const double _maxLat = 17.55;
  static const double _minLng = 78.25;
  static const double _maxLng = 78.65;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_searchFocusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _httpClient.close();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _houseNoController.dispose();
    _phoneController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!_isNewAddressMode) return;
    final query = _searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _isSearching = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': query,
        'limit': '8',
        'lang': 'en',
        'lat': '17.3850',
        'lon': '78.4867',
      });
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'BandiWalaApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        final suggestions = features.map((f) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final coords = f['geometry']['coordinates'] as List;
          final name = props['name'] as String? ?? '';
          final street = props['street'] as String? ?? '';
          final city =
              props['city'] as String? ?? props['county'] as String? ?? '';
          final state = props['state'] as String? ?? '';
          final district = props['district'] as String? ?? '';
          final shortName = name.isNotEmpty
              ? name
              : street.isNotEmpty
              ? street
              : city.isNotEmpty
              ? city
              : query;
          final parts = <String>[];
          if (name.isNotEmpty) parts.add(name);
          if (street.isNotEmpty && street != name) parts.add(street);
          if (district.isNotEmpty && district != name) parts.add(district);
          if (city.isNotEmpty && city != name && city != district)
            parts.add(city);
          if (state.isNotEmpty) parts.add(state);
          return _PlaceSuggestion(
            displayName: parts.isNotEmpty ? parts.take(4).join(', ') : query,
            shortName: shortName,
            lat: (coords[1] as num).toDouble(),
            lon: (coords[0] as num).toDouble(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _isSearching = false;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
        _fetchSuggestionsFallback(query);
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isSearching = false);
        _fetchSuggestionsFallback(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _fetchSuggestionsFallback(query);
      }
    }
  }

  Future<void> _fetchSuggestionsFallback(String query) async {
    if (!mounted || query.isEmpty) return;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'in',
        'accept-language': 'en',
      });
      final response = await _httpClient
          .get(
            uri,
            headers: {
              'User-Agent': 'BandiWalaApp/1.0 (bandiwala.app)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final suggestions = data.map((item) {
          final addr = item['address'] as Map<String, dynamic>? ?? {};
          final name = item['name'] as String? ?? '';
          final road =
              addr['road'] as String? ?? addr['pedestrian'] as String? ?? '';
          final suburb =
              addr['suburb'] as String? ??
              addr['neighbourhood'] as String? ??
              '';
          final city =
              addr['city'] as String? ??
              addr['town'] as String? ??
              addr['county'] as String? ??
              '';
          final state = addr['state'] as String? ?? '';
          final shortName = name.isNotEmpty
              ? name
              : road.isNotEmpty
              ? road
              : city.isNotEmpty
              ? city
              : query;
          final parts = <String>[];
          if (name.isNotEmpty) parts.add(name);
          if (road.isNotEmpty && road != name) parts.add(road);
          if (suburb.isNotEmpty) parts.add(suburb);
          if (city.isNotEmpty) parts.add(city);
          if (state.isNotEmpty) parts.add(state);
          return _PlaceSuggestion(
            displayName: parts.isNotEmpty
                ? parts.take(4).join(', ')
                : item['display_name'] as String? ?? query,
            shortName: shortName,
            lat: double.parse(item['lat'].toString()),
            lon: double.parse(item['lon'].toString()),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Nominatim fallback error: $e');
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    if (mounted) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
        _isSearching = false;
      });
    }
    _searchFocusNode.unfocus();
    final pos = LatLng(suggestion.lat, suggestion.lon);
    _searchController.text = suggestion.displayName;
    final address = await _reverseGeocode(pos);
    if (!mounted) return;
    setState(() {
      _selectedPosition = pos;
      _fetchedAddress = address.isNotEmpty ? address : suggestion.displayName;
      _isOutsideHyderabad = !_isInHyderabad(pos);
    });
    if (_isMapReady) _mapController.move(pos, 16.0);
  }

  // ─── Reverse geocode — returns clean area name only ───────────────────────

  Future<String> _reverseGeocode(LatLng position) async {
    // 1️⃣ Photon reverse (fastest)
    try {
      final uri = Uri.https('photon.komoot.io', '/reverse', {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'limit': '1',
      });
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'BandiWalaApp/1.0'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final props =
              features.first['properties'] as Map<String, dynamic>? ?? {};
          final name = props['name'] as String? ?? '';
          final street = props['street'] as String? ?? '';
          final city =
              props['city'] as String? ?? props['county'] as String? ?? '';
          final state = props['state'] as String? ?? '';
          final parts = <String>[];
          if (name.isNotEmpty) parts.add(name);
          if (street.isNotEmpty && street != name) parts.add(street);
          if (city.isNotEmpty) parts.add(city);
          if (state.isNotEmpty) parts.add(state);
          if (parts.isNotEmpty) return parts.take(3).join(', ');
        }
      }
    } catch (e) {
      debugPrint('Photon reverse error: $e');
    }

    // 2️⃣ Nominatim reverse fallback
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
      });
      final response = await _httpClient
          .get(
            uri,
            headers: {
              'User-Agent': 'BandiWalaApp/1.0 (bandiwala.app)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final road =
            addr['road'] as String? ?? addr['pedestrian'] as String? ?? '';
        final suburb =
            addr['suburb'] as String? ?? addr['neighbourhood'] as String? ?? '';
        final city =
            addr['city'] as String? ??
            addr['town'] as String? ??
            addr['county'] as String? ??
            '';
        final state = addr['state'] as String? ?? '';
        final parts = <String>[];
        if (road.isNotEmpty) parts.add(road);
        if (suburb.isNotEmpty) parts.add(suburb);
        if (city.isNotEmpty) parts.add(city);
        if (state.isNotEmpty) parts.add(state);
        if (parts.isNotEmpty) return parts.take(3).join(', ');
      }
    } catch (e) {
      debugPrint('Nominatim reverse error: $e');
    }
    return '';
  }

  Future<void> _loadSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_locations') ?? [];
      if (mounted) {
        setState(() {
          _savedLocations = list
              .map((j) => SavedLocation.fromJson(jsonDecode(j)))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Load saved locations error: $e');
    }
  }

  bool _isInHyderabad(LatLng pos) =>
      pos.latitude >= _minLat &&
      pos.latitude <= _maxLat &&
      pos.longitude >= _minLng &&
      pos.longitude <= _maxLng;

  Future<void> _enterCurrentLocationMode() async {
    setState(() {
      _showModeSelection = false;
      _isCurrentLocationMode = true;
      _isNewAddressMode = false;
      _isMapReady = false;
      _isFetchingLocation = true;
    });
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    if (mounted) setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showPermissionDialog(
          'Enable Location Services',
          'Turn on device location to auto-fill your address.',
        );
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showPermissionDialog(
          'Permission Needed',
          'Allow location access so we can deliver to you.',
        );
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }

      // ✅ bestForNavigation = maximum GPS precision
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      // ✅ Raw full-precision coordinates — no rounding
      final pos = LatLng(position.latitude, position.longitude);
      final address = await _reverseGeocode(pos);

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _selectedPosition = pos;
        _fetchedAddress = address.isNotEmpty ? address : 'Current Location';
        _searchController.text = _fetchedAddress;
        _isOutsideHyderabad = !_isInHyderabad(pos);
        _isFetchingLocation = false;
      });

      if (_isMapReady) _mapController.move(pos, 17.0);
    } catch (e) {
      debugPrint('Fetch current location error: $e');
      if (!mounted) return;
      setState(() => _isFetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch location. Try again.')),
      );
    }
  }

  void _enterNewAddressMode() {
    setState(() {
      _showModeSelection = false;
      _isCurrentLocationMode = false;
      _isNewAddressMode = true;
      _isMapReady = false;
      _selectedPosition = null;
      _fetchedAddress = '';
      _suggestions = [];
      _showSuggestions = false;
      _searchController.clear();
      _houseNoController.clear();
      _phoneController.clear();
      _selectedLabel = 'Home';
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _isNewAddressMode) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (!_isNewAddressMode || !_isMapReady) return;
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
    }
    final address = await _reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      _selectedPosition = point;
      _fetchedAddress = address.isNotEmpty ? address : 'Selected Location';
      _searchController.text = _fetchedAddress;
      _isOutsideHyderabad = !_isInHyderabad(point);
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  bool _isDuplicate(SavedLocation loc) =>
      _savedLocations.any((e) => e.isSameLocation(loc));

  Future<void> _saveLocation() async {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }
    if (_houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter door number or landmark')),
      );
      return;
    }

    // ✅ address = human-readable area name
    // ✅ latitude/longitude = full precision raw doubles
    final location = SavedLocation(
      address: _fetchedAddress.isNotEmpty
          ? _fetchedAddress
          : _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : 'Selected Location',
      latitude: _selectedPosition!.latitude, // e.g. 17.476388123456
      longitude: _selectedPosition!.longitude, // e.g. 78.390350456789
      houseNo: _houseNoController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      label: _selectedLabel,
    );

    if (_isDuplicate(location)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Text('Duplicate Location'),
            ],
          ),
          content: const Text(
            'An address at this location already exists in your saved addresses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _proceedToSave(location);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bandiwalaYellow,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      return;
    }
    await _proceedToSave(location);
  }

  Future<void> _proceedToSave(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_locations') ?? [];
    list.insert(0, jsonEncode(location.toJson()));
    if (list.length > 20) list.removeLast();
    await prefs.setStringList('saved_locations', list);
    if (mounted) setState(() => _savedLocations.insert(0, location));
    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  Future<void> _selectSavedLocation(SavedLocation location) async {
    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  void _showPermissionDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchCurrentLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bandiwalaYellow,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _showModeSelection ? _buildModeSelection() : _buildMapView(),
    );
  }

  Widget _buildModeSelection() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Select Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeButton(
                          icon: Icons.my_location,
                          title: 'Use Current\nLocation',
                          subtitle: 'Auto-detect GPS',
                          onTap: _enterCurrentLocationMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeButton(
                          icon: Icons.add_location_alt_outlined,
                          title: 'Add New\nAddress',
                          subtitle: 'Search & pin on map',
                          onTap: _enterNewAddressMode,
                        ),
                      ),
                    ],
                  ),
                  if (_savedLocations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Saved Addresses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._savedLocations.map(_buildSavedLocationTile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bandiwalaYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: bandiwalaYellow, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Shows area name + lat/lng coordinates in saved tile
  Widget _buildSavedLocationTile(SavedLocation loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectSavedLocation(loc),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bandiwalaYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  loc.label == 'Home'
                      ? Icons.home
                      : loc.label == 'Work'
                      ? Icons.work
                      : Icons.location_on,
                  color: bandiwalaYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          loc.label ?? 'Other',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (loc.houseNo != null && loc.houseNo!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${loc.houseNo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // ✅ Area name shown here
                    Text(
                      loc.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // ✅ Precise coordinates shown below area name
                    Text(
                      loc.coordinatesDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(17.3850, 78.4867),
            initialZoom: 14.0,
            onMapReady: () {
              if (mounted) setState(() => _isMapReady = true);
              final target = _selectedPosition ?? _currentPosition;
              if (target != null) _mapController.move(target, 16.0);
            },
            onTap: _isNewAddressMode
                ? (tapPosition, point) => _handleMapTap(point)
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxNativeZoom: 20,
              userAgentPackageName: 'com.bandiwala.user',
            ),
            if (_selectedPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition!,
                    width: 40,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () {
                          _debounce?.cancel();
                          setState(() {
                            _showModeSelection = true;
                            _isCurrentLocationMode = false;
                            _isNewAddressMode = false;
                            _isMapReady = false;
                            _selectedPosition = null;
                            _suggestions = [];
                            _showSuggestions = false;
                            _fetchedAddress = '';
                            _searchController.clear();
                            _houseNoController.clear();
                            _phoneController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isNewAddressMode
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: const TextStyle(fontSize: 14),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Search city, area or street...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  prefixIcon: _isSearching
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: bandiwalaYellow,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.search,
                                          color: Colors.grey.shade500,
                                          size: 20,
                                        ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.grey.shade500,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _suggestions = [];
                                              _showSuggestions = false;
                                              _selectedPosition = null;
                                              _fetchedAddress = '';
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (value) {
                                  if (_suggestions.isNotEmpty) {
                                    _selectSuggestion(_suggestions.first);
                                  } else if (value.trim().isNotEmpty) {
                                    _fetchSuggestions(value.trim());
                                  }
                                },
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: bandiwalaYellow,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Using Current Location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              if (_showSuggestions && _suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(64, 4, 8, 0),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Colors.black26,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.white,
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (ctx, i) {
                            final s = _suggestions[i];
                            return InkWell(
                              onTap: () => _selectSuggestion(s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.grey.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.shortName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (s.displayName != s.shortName)
                                            Text(
                                              s.displayName,
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
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

              if (_isOutsideHyderabad)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Outside Hyderabad service area — you can still save this address',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          bottom: 330,
          child: FloatingActionButton.small(
            heroTag: 'gps_fab',
            onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
            backgroundColor: Colors.white,
            elevation: 4,
            child: _isFetchingLocation
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: bandiwalaYellow,
                    ),
                  )
                : Icon(Icons.gps_fixed, color: bandiwalaYellow, size: 22),
          ),
        ),

        DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.30,
          maxChildSize: 0.85,
          builder: (ctx, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCurrentLocationMode
                            ? 'Confirm Current Location'
                            : 'Add Address Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isFetchingLocation)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bandiwalaYellow,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Fetching your location...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_fetchedAddress.isNotEmpty)
                        // ✅ Address preview: area name + precise coordinates
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fetchedAddress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedPosition != null) ...[
                                const SizedBox(height: 6),
                                // ✅ Show lat/lng with 6 decimal precision
                                Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      size: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                                      '${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                      else if (_isNewAddressMode && _selectedPosition == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Search above or tap anywhere on the map to pin your address',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      const Text(
                        'Label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLabelChip('Home', Icons.home),
                          const SizedBox(width: 8),
                          _buildLabelChip('Work', Icons.work),
                          const SizedBox(width: 8),
                          _buildLabelChip('Other', Icons.location_on),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _houseNoController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Door No / Flat / Landmark *',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.home_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: bandiwalaYellow,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone (optional)',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: bandiwalaYellow,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedPosition != null &&
                                  !_isFetchingLocation)
                              ? _saveLocation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bandiwalaYellow,
                            foregroundColor: Colors.black87,
                            disabledBackgroundColor: Colors.grey.shade200,
                            disabledForegroundColor: Colors.grey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save & Use This Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final bool selected = _selectedLabel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLabel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? bandiwalaYellow : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? bandiwalaYellow : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.black87 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
