import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../providers/service_zones_provider.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import '../core/theme/theme.dart';
import '../core/theme/map_style.dart';
// ─── Shared model ─────────────────────────────────────────────────────────────

// ─── Shared model consolidated into SavedAddress in app_user.dart ────────────────

// ─── Autocomplete model ───────────────────────────────────────────────────────

class _PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double? lat;
  final double? lon;
  final String? placeId;

  _PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    this.lat,
    this.lon,
    this.placeId,
  });
}

// ─── LocationPickerPage ───────────────────────────────────────────────────────
// Single page for: selecting an address, adding new, editing, deleting.

class LocationPickerPage extends ConsumerStatefulWidget {
  final Function(SavedAddress)? onLocationSelected;

  /// The currently active address — used to highlight the selected tile.
  final SavedAddress? activeAddress;
  const LocationPickerPage({
    super.key,
    this.onLocationSelected,
    this.activeAddress,
  });

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  static const Color bandiwalaYellow = AppColors.primary;

  bool _showModeSelection = true;
  bool _isCurrentLocationMode = false;
  bool _isNewAddressMode = false;
  bool _isMapReady = false;

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isOutsideHyderabad = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customLabelController = TextEditingController();

  List<SavedAddress> _savedAddresses = [];
  bool _isFetchingLocation = false;
  String _selectedLabel = 'Home';
  String _fetchedAddress = '';

  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isMapIdleUpdating = false;
  Timer? _debounce;

  final http.Client _httpClient = http.Client();
  static const String _googleMapsApiKey =
      'AIzaSyDKVT8aUdGm6EcR8DdRdh0QxI2oj7HRo5E';
  String? _sessionToken;

  void _generateSessionToken() {
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  }

  static const double _minLat = 17.25;
  static const double _maxLat = 17.55;
  static const double _minLng = 78.25;
  static const double _maxLng = 78.65;

  @override
  void initState() {
    super.initState();
    _syncAddressesFromProvider();
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

    // Default phone from user profile
    final user = ref.read(userProvider).valueOrNull;
    if (user != null && user.phone.isNotEmpty) {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _httpClient.close();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _customLabelController.dispose();
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
    if (_sessionToken == null) _generateSessionToken();

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'key': _googleMapsApiKey,
          'location': '17.3850,78.4867', // Hyderabad center
          'radius': '50000',
          'strictbounds': 'false',
          'components': 'country:in',
          'language': 'en',
          'sessiontoken': _sessionToken,
        },
      );

      final response = await _httpClient.get(uri);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions.map((p) {
            final description = p['description'] as String;
            final structuredFormatting =
                p['structured_formatting'] as Map<String, dynamic>;
            final mainText = structuredFormatting['main_text'] as String;

            return _PlaceSuggestion(
              displayName: description,
              shortName: mainText,
              placeId: p['place_id'],
            );
          }).toList();

          setState(() {
            _suggestions = suggestions;
            _isSearching = false;
            _showSuggestions = suggestions.isNotEmpty;
          });
          return;
        } else if (data['status'] == 'ZERO_RESULTS') {
          setState(() {
            _suggestions = [];
            _isSearching = false;
            _showSuggestions = false;
          });
          return;
        } else {
          debugPrint('Google Autocomplete Error Status: ${data['status']}');
          if (data['error_message'] != null) {
            debugPrint('Error Message: ${data['error_message']}');
          }
          // Fallback to nominatim if Google returns an error (denied, over limit, etc)
          await _fetchSuggestionsFallback(query);
          return;
        }
      } else {
        debugPrint('Google API HTTP Error: ${response.statusCode}');
        await _fetchSuggestionsFallback(query);
      }
    } catch (e) {
      debugPrint('Google Autocomplete catch error: $e');
      await _fetchSuggestionsFallback(query);
    }
  }

  Future<void> _fetchSuggestionsFallback(String query) async {
    if (!mounted || query.isEmpty) return;
    try {
      // Photon API is a fast, free alternative based on OpenStreetMap
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': query,
        'limit': '10',
        'lang': 'en',
        'lat': '17.3850',
        'lon': '78.4867',
      });
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'BandiWalaApp/1.0'})
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        final suggestions = features.map((f) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final coords = f['geometry']['coordinates'] as List;
          final name = props['name'] as String? ?? '';
          final city = props['city'] as String? ?? '';
          final state = props['state'] as String? ?? '';
          final parts = <String>[];
          if (name.isNotEmpty) parts.add(name);
          if (city.isNotEmpty) parts.add(city);
          if (state.isNotEmpty) parts.add(state);

          return _PlaceSuggestion(
            displayName: parts.join(', '),
            shortName: name.isNotEmpty ? name : query,
            lat: (coords[1] as num).toDouble(),
            lon: (coords[0] as num).toDouble(),
          );
        }).toList();

        setState(() {
          _suggestions = suggestions;
          _isSearching = false;
          _showSuggestions = suggestions.isNotEmpty;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint('Fallback search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<LatLng> _getPlaceDetails(String placeId) async {
    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
            'place_id': placeId,
            'fields': 'geometry',
            'key': _googleMapsApiKey,
            'sessiontoken': _sessionToken,
          });
      final response = await _httpClient.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint('Google Place Details error: $e');
    }
    return const LatLng(17.3850, 78.4867); // Default to Hyderabad center
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

    LatLng pos;
    if (suggestion.placeId != null && suggestion.lat == null) {
      pos = await _getPlaceDetails(suggestion.placeId!);
    } else {
      pos = LatLng(suggestion.lat ?? 0.0, suggestion.lon ?? 0.0);
    }

    _searchController.text = suggestion.displayName;
    final address = await _reverseGeocode(pos);
    _sessionToken = null; // Reset session token after selection

    if (!mounted) return;
    setState(() {
      _selectedPosition = pos;
      _fetchedAddress = address.isNotEmpty ? address : suggestion.displayName;
      _isOutsideHyderabad = !_isInHyderabad(pos);
    });
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  // ─── Reverse geocode — returns clean area name only ───────────────────────

  Future<String> _reverseGeocode(LatLng position) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${position.latitude},${position.longitude}',
        'key': _googleMapsApiKey,
        'language': 'en',
      });
      final response = await _httpClient.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            // Use the first result (most precise)
            final formattedAddress =
                results.first['formatted_address'] as String;
            // Often we want just the area name, but formatted_address is good.
            // Let's try to extract a slightly shorter area name if possible.
            final addressComponents =
                results.first['address_components'] as List;
            final sublocality = addressComponents.firstWhere(
              (c) => (c['types'] as List).contains('sublocality'),
              orElse: () => null,
            )?['long_name'];
            final locality = addressComponents.firstWhere(
              (c) => (c['types'] as List).contains('locality'),
              orElse: () => null,
            )?['long_name'];

            if (sublocality != null && locality != null) {
              return '$sublocality, $locality';
            }
            return formattedAddress.split(',').take(3).join(',').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Google Reverse Geocode error: $e');
    }

    // Fallback to nominatim reverse if google fails
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
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['display_name'] ?? '';
      }
    } catch (e) {
      debugPrint('Reverse geocode fallback error: $e');
    }
    return '';
  }

  void _syncAddressesFromProvider() {
    final addresses = ref.read(userProvider).valueOrNull?.savedAddresses ?? [];
    _savedAddresses = addresses.map(_toSavedAddress).toList();
  }

  // Convert AppUser's SavedAddress to our model (now the same)
  SavedAddress _toSavedAddress(SavedAddress a) => a;

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

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog(
          'Location Permission Denied',
          'You have permanently denied location access. Please enable it in app settings so we can provide service at your location.',
          isSettings: true,
        );
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog(
            'Permission Needed',
            'Allow location access so we can deliver to you.',
          );
          if (mounted) setState(() => _isFetchingLocation = false);
          return;
        }
        if (permission == LocationPermission.deniedForever) {
          _showPermissionDialog(
            'Location Permission Denied',
            'Please enable location access in app settings to continue.',
            isSettings: true,
          );
          if (mounted) setState(() => _isFetchingLocation = false);
          return;
        }
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

      if (_mapController != null)
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 17.0));
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
      _addressController.clear();

      // Auto-fill phone from user profile
      final user = ref.read(userProvider).valueOrNull;
      if (user != null && user.phone.isNotEmpty) {
        _phoneController.text = user.phone;
      } else {
        _phoneController.clear();
      }

      _customLabelController.clear();
      _selectedLabel = 'Home';
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _isNewAddressMode) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _updateAddressFromMapIdle(LatLng point) async {
    if (!_isNewAddressMode || !_isMapReady) return;
    if (_isMapIdleUpdating) return;

    _isMapIdleUpdating = true;
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
      _isMapIdleUpdating = false;
    });
  }

  bool _isDuplicate(SavedAddress loc) =>
      _savedAddresses.any((e) => e.isSameLocation(loc));

  Future<void> _saveLocation() async {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter house number or landmark')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    // ✅ geolocation = human-readable area name
    // ✅ address = specific door no / street
    // ✅ latitude/longitude = full precision raw doubles
    final location = SavedAddress(
      geolocation: _fetchedAddress.isNotEmpty
          ? _fetchedAddress
          : _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : 'Selected Location',
      latitude: _selectedPosition!.latitude, // e.g. 17.476388123456
      longitude: _selectedPosition!.longitude, // e.g. 78.390350456789
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      label: _selectedLabel == 'Other'
          ? _customLabelController.text.trim()
          : _selectedLabel,
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

  Future<void> _proceedToSave(SavedAddress location) async {
    await ref.read(userProvider.notifier).addAddress(_toSavedAddress(location));
    if (mounted) setState(() => _savedAddresses.insert(0, location));
    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  Future<void> _selectSavedAddress(SavedAddress location) async {
    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  void _showPermissionDialog(
    String title,
    String message, {
    bool isSettings = false,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSettings ? Icons.settings : Icons.location_off,
              color: isSettings ? Colors.blue.shade600 : Colors.orange.shade600,
              size: 24,
            ),
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
              if (isSettings) {
                Geolocator.openAppSettings();
              } else {
                _fetchCurrentLocation();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bandiwalaYellow,
              foregroundColor: Colors.black87,
            ),
            child: Text(isSettings ? 'Open Settings' : 'Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _showModeSelection
          ? _buildModeSelection(context)
          : _buildMapView(context),
    );
  }

  Widget _buildModeSelection(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Select Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
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
                          context: context,
                          icon: Icons.my_location,
                          title: 'Use Current\nLocation',
                          subtitle: 'Auto-detect GPS',
                          onTap: _enterCurrentLocationMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeButton(
                          context: context,
                          icon: Icons.add_location_alt_outlined,
                          title: 'Add New\nAddress',
                          subtitle: 'Search & pin on map',
                          onTap: _enterNewAddressMode,
                        ),
                      ),
                    ],
                  ),
                  if (_savedAddresses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Saved Addresses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      _savedAddresses.length,
                      (i) => _buildSavedAddressTile(
                        context,
                        _savedAddresses[i],
                        i,
                      ),
                    ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 
                isDark ? 0.08 : 0.04,
              ),
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
                color: bandiwalaYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: bandiwalaYellow, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressTile(
    BuildContext context,
    SavedAddress loc,
    int index,
  ) {
    final theme = Theme.of(context);
    final active = widget.activeAddress;
    final isSelected =
        active != null &&
        (active.latitude - loc.latitude).abs() < 0.0005 &&
        (active.longitude - loc.longitude).abs() < 0.0005;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? bandiwalaYellow.withOpacity(0.12) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? bandiwalaYellow : theme.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectSavedAddress(loc),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: bandiwalaYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (loc.address != null && loc.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        loc.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => _editSavedAddress(index),
                tooltip: 'Edit',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade300,
                ),
                onPressed: () => _deleteSavedAddress(index),
                tooltip: 'Delete',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSavedAddress(int index) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(userProvider.notifier).deleteAddress(index);
    if (mounted) setState(() => _savedAddresses.removeAt(index));
  }

  Future<void> _editSavedAddress(int index) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = _savedAddresses[index];
    final addressCtrl = TextEditingController(text: loc.address ?? '');
    final phoneCtrl = TextEditingController(text: loc.phone);
    final customLabelCtrl = TextEditingController();
    String label = loc.label ?? 'Other';

    if (label != 'Home' && label != 'Work') {
      customLabelCtrl.text = label;
      label = 'Other';
    }

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Edit Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.geolocation,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) {
                  final sel = label == l;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l),
                        selected: sel,
                        onSelected: (_) => setModal(() => label = l),
                        selectedColor: bandiwalaYellow,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? (isDark ? Colors.black : Colors.black87)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address (House No, Building, Area) *',
                  prefixIcon: const Icon(Icons.home_outlined),
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: const Icon(Icons.phone_outlined),
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
                ),
              ),
              if (label == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customLabelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Custom Label *',
                    prefixIcon: const Icon(Icons.label_outline),
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
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (addressCtrl.text.trim().isEmpty) return;
                    if (phoneCtrl.text.trim().isEmpty) return;
                    String finalLabel = label;
                    if (label == 'Other') {
                      if (customLabelCtrl.text.trim().isEmpty) return;
                      finalLabel = customLabelCtrl.text.trim();
                    }
                    Navigator.pop(ctx, {
                      'address': addressCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'label': finalLabel,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bandiwalaYellow,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    final updatedLoc = SavedAddress(
      geolocation: loc.geolocation,
      latitude: loc.latitude,
      longitude: loc.longitude,
      address: result['address'],
      phone: result['phone']!,
      label: result['label']!,
    );
    await ref.read(userProvider.notifier).updateAddress(index, updatedLoc);
    if (mounted) {
      setState(() => _savedAddresses[index] = updatedLoc);
    }
  }

  Set<Circle> _buildServiceAreaCircles() {
    final zones = ref.watch(serviceZonesProvider).valueOrNull ?? [];
    return zones.map((zone) {
      return Circle(
        circleId: CircleId(zone.name),
        center: LatLng(zone.lat, zone.lng),
        radius: zone.radiusMeters,
        fillColor: bandiwalaYellow.withOpacity(0.15),
        strokeColor: bandiwalaYellow,
        strokeWidth: 2,
      );
    }).toSet();
  }

  Widget _buildMapView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(17.3850, 78.4867),
            zoom: 14.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (isDark) {
              _mapController!.setMapStyle(MapStyles.darkStyle);
            }
            if (mounted) setState(() => _isMapReady = true);
            final target = _selectedPosition ?? _currentPosition;
            if (target != null) {
              _mapController!.moveCamera(
                CameraUpdate.newLatLngZoom(target, 16.0),
              );
            }
          },
          onCameraMove: (position) {
            if (_isNewAddressMode) {
              _selectedPosition = position.target;
            }
          },
          onCameraIdle: () {
            if (_isNewAddressMode && _selectedPosition != null && _isMapReady) {
              _updateAddressFromMapIdle(_selectedPosition!);
            }
          },
          markers: {},
          circles: _buildServiceAreaCircles(),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        if (_isNewAddressMode)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.0),
              child: Icon(Icons.location_on, size: 45, color: Colors.red),
            ),
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
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
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
                            _addressController.clear();
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
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Search city, area or street...',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
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
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          size: 20,
                                        ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
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
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(0.1),
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
                                  Text(
                                    'Using Current Location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
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
                    shadowColor: (isDark ? Colors.white : Colors.black26),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: theme.cardColor,
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: theme.dividerColor),
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
                                      color: theme.colorScheme.onSurfaceVariant,
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
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (s.displayName != s.shortName)
                                            Text(
                                              s.displayName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withOpacity(0.15)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: isDark
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We currently only serve Hyderabad. Please select a location within Hyderabad.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.red.shade200
                                : Colors.red.shade800,
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
            backgroundColor: theme.cardColor,
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
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.1,
                  ),
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
                      color: theme.dividerColor,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
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
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_fetchedAddress.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceVariant.withOpacity(
                                    0.3,
                                  )
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Geolocation',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: bandiwalaYellow,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _fetchedAddress,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedPosition != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      size: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                                      '${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Text(
                        'Label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLabelChip(context, 'Home', Icons.home),
                          const SizedBox(width: 8),
                          _buildLabelChip(context, 'Work', Icons.work),
                          const SizedBox(width: 8),
                          _buildLabelChip(context, 'Other', Icons.location_on),
                        ],
                      ),

                      if (_selectedLabel == 'Other') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _customLabelController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Custom Label (e.g. Friend\'s House) *',
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.label_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: bandiwalaYellow,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Address (House No, Building, Area) *',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.home_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor),
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
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone *',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor),
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
                                  !_isFetchingLocation &&
                                  !_isOutsideHyderabad)
                              ? _saveLocation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bandiwalaYellow,
                            foregroundColor: Colors.black87,
                            disabledBackgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
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

  Widget _buildLabelChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool selected = _selectedLabel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLabel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? bandiwalaYellow
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? bandiwalaYellow : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? (isDark ? Colors.black : Colors.black87)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? (isDark ? Colors.black : Colors.black87)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
