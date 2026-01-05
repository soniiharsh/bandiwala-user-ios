import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

class SavedLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? houseNo;
  final String? phone;
  final String? label; // Home / Work / Other

  SavedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.houseNo,
    this.phone,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'houseNo': houseNo,
    'phone': phone,
    'label': label,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    address: json['address'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    houseNo: json['houseNo'],
    phone: json['phone'],
    label: json['label'],
  );
}

class LocationPickerPage extends StatefulWidget {
  final Function(SavedLocation)? onLocationSelected;
  const LocationPickerPage({super.key, this.onLocationSelected});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  // Hyderabad bounds (slightly expanded for flexibility)
  static const double hyderabadMinLat = 17.25;
  static const double hyderabadMaxLat = 17.55;
  static const double hyderabadMinLng = 78.25;
  static const double hyderabadMaxLng = 78.65;

  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String? _currentPlaceName;
  bool _isOutsideHyderabad = false;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _showPermissionScreen = true;

  // Label selection: Home / Work / Other
  String _selectedLabel = 'Other';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationPermissionDialog(
            'Turn On Location',
            'Enable location services to find food near you',
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationPermissionDialog(
            'Location Permission Required',
            'Allow location access for accurate delivery',
          );
        }
        return;
      }

      setState(() {
        _hasLocationPermission = true;
        _showPermissionScreen = false;
      });

      await Future.wait([
        _loadSavedLocations(),
        _getCurrentLocation(),
      ]);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Location init error: $e');
      setState(() {
        _showPermissionScreen = false;
        _hasLocationPermission = false;
      });
      await _loadSavedLocations();
      setState(() => _isLoading = false);
    }
  }

  bool _isInHyderabad(LatLng position) {
    return position.latitude >= hyderabadMinLat &&
        position.latitude <= hyderabadMaxLat &&
        position.longitude >= hyderabadMinLng &&
        position.longitude <= hyderabadMaxLng;
  }

  Future<void> _updatePlaceInfo(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String?> locationParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.name,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .toList();

        String? placeName =
        locationParts.isNotEmpty ? locationParts.first : 'Current Location';

        setState(() {
          _currentPlaceName = placeName;
          _isOutsideHyderabad = !_isInHyderabad(position);
        });
      }
    } catch (e) {
      setState(() {
        _currentPlaceName = 'Current Location';
        _isOutsideHyderabad = !_isInHyderabad(position);
      });
    }
  }

  void _showLocationPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showPermissionScreen = false;
                _hasLocationPermission = false;
              });
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Allow Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList('saved_locations') ?? [];
    setState(() {
      _savedLocations = locationsJson
          .map((json) => SavedLocation.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final pos = LatLng(position.latitude, position.longitude);
      await _updatePlaceInfo(pos);
      setState(() {
        _currentPosition = pos;
        _selectedPosition = pos;
      });
      _mapController.move(pos, 16.0);
      await _reverseGeocode(pos);
    } catch (e) {
      final hyderabad = const LatLng(17.3850, 78.4867);
      await _updatePlaceInfo(hyderabad);
      setState(() {
        _currentPosition = hyderabad;
        _selectedPosition = hyderabad;
      });
      _mapController.move(hyderabad, 14.0);
      await _reverseGeocode(hyderabad);
    }
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final newPos =
        LatLng(locations.first.latitude, locations.first.longitude);
        await _updatePlaceInfo(newPos);
        setState(() => _selectedPosition = newPos);
        _mapController.move(newPos, 16.0);
        await _reverseGeocode(newPos);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed')),
        );
      }
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .join(', ');
        _searchController.text =
        address.isNotEmpty ? address : 'Selected Location';
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      _searchController.text = 'Selected Location';
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    await _reverseGeocode(_selectedPosition!);

    // Prefix address with label for quick identification if needed
    final labelPrefix =
    (_selectedLabel.isNotEmpty && _selectedLabel != 'Other')
        ? '$_selectedLabel - '
        : '';

    final location = SavedLocation(
      address: _searchController.text.trim().isEmpty
          ? '${labelPrefix}Selected Location'
          : '$labelPrefix${_searchController.text.trim()}',
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      houseNo: _houseNoController.text.trim().isNotEmpty
          ? _houseNoController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      label: _selectedLabel,
    );

    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList('saved_locations') ?? [];
    locationsJson.insert(0, jsonEncode(location.toJson()));
    if (locationsJson.length > 20) locationsJson.removeLast();
    await prefs.setStringList('saved_locations', locationsJson);

    setState(() {
      _savedLocations.insert(0, location);
    });

    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  Future<void> _selectSavedLocation(SavedLocation location) async {
    final pos = LatLng(location.latitude, location.longitude);
    await _updatePlaceInfo(pos);
    _searchController.text = location.address;
    _houseNoController.text = location.houseNo ?? '';
    _phoneController.text = location.phone ?? '';
    _selectedLabel = location.label ?? 'Other';
    _mapController.move(pos, 16.0);
    setState(() => _selectedPosition = pos);
  }

  // When user taps map: move to that point and position pin to appear
  // visually over the GPS button area (bottom-center).
  Future<void> _handleMapTap(LatLng point) async {
    await _updatePlaceInfo(point);
    setState(() => _selectedPosition = point);
    await _reverseGeocode(point);

    // Move camera slightly up so pin appears roughly above bottom controls
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    if (_showPermissionScreen) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 120, color: bandiwalaYellow),
                  const SizedBox(height: 32),
                  const Text(
                    'Find Food Near You',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Allow location access to see street food stalls near your location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _checkLocationPermission,
                      icon: const Icon(Icons.location_on,
                          color: Colors.black87),
                      label: const Text(
                        'Enable Location',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bandiwalaYellow,
                        foregroundColor: Colors.black87,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPermissionScreen = false;
                        _hasLocationPermission = false;
                      });
                    },
                    child: const Text('Continue without location'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(17.3850, 78.4867),
              initialZoom: 14.0,
              onTap: (tapPosition, point) async {
                await _handleMapTap(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxNativeZoom: 20,
                userAgentPackageName: 'com.example.bandiwala',
              ),

              if (_selectedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isOutsideHyderabad
                              ? Colors.orange.shade400
                              : bandiwalaYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isOutsideHyderabad
                                  ? Colors.orange
                                  : bandiwalaYellow)
                                  .withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // DYNAMIC TOP BAR - Shows specific area name
          SafeArea(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isOutsideHyderabad
                          ? Colors.orange.shade400
                          : bandiwalaYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isOutsideHyderabad
                          ? Icons.location_off
                          : Icons.location_on,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentPlaceName ?? 'Loading location...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isOutsideHyderabad
                                ? Colors.orange.shade700
                                : const Color(0xFF212121),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isOutsideHyderabad &&
                            _currentPlaceName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Delivering from $_currentPlaceName',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
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

          // Search Bar (positioned below top bar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 140, left: 20, right: 20, bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search for area, street name...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.grey.shade600),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
            ),
          ),

          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag Handle
                  Container(
                    margin:
                    const EdgeInsets.only(top: 16, bottom: 24),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Move Pin Instruction
                  Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        bandiwalaYellow,
                        const Color(0xFFFFA000)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color:
                            bandiwalaYellow.withOpacity(0.3),
                            blurRadius: 15),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Move pin to your delivery location',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              if (_isOutsideHyderabad)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Note: Delivery from $_currentPlaceName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              Text(
                                'Tap map to place red pin at exact location',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white
                                        .withOpacity(0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Saved Locations
                  if (_savedLocations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24),
                      child: Text(
                        'Saved Locations',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: _savedLocations.length,
                        itemBuilder: (context, index) {
                          final loc = _savedLocations[index];
                          return Container(
                            width: 160,
                            margin:
                            const EdgeInsets.only(right: 16),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16)),
                              child: InkWell(
                                borderRadius:
                                BorderRadius.circular(16),
                                onTap: () =>
                                    _selectSavedLocation(loc),
                                child: Padding(
                                  padding:
                                  const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                            const EdgeInsets.all(
                                                6),
                                            decoration:
                                            BoxDecoration(
                                              color: Colors
                                                  .green.shade400,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.location_on,
                                                color: Colors.white,
                                                size: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              loc.address,
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight
                                                      .w600,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (loc.label ?? '')
                                            .toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                            Colors.grey.shade600,
                                            fontWeight:
                                            FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Address Form + Label selector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Address Details',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            if (_isOutsideHyderabad)
                              Container(
                                margin: const EdgeInsets.only(
                                    left: 8),
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Outside area',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors
                                        .orange.shade700,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Label chips: Home / Work / Other
                        Row(
                          children: [
                            _buildLabelChip('Home'),
                            const SizedBox(width: 8),
                            _buildLabelChip('Work'),
                            const SizedBox(width: 8),
                            _buildLabelChip('Other'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _houseNoController,
                          decoration: InputDecoration(
                            labelText: 'Eg. House no, landmark',
                            prefixIcon: Icon(Icons.home,
                                color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: bandiwalaYellow,
                                  width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone,
                                color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: bandiwalaYellow,
                                  width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Save Button
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bandiwalaYellow,
                        foregroundColor: Colors.black87,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Save Address${_isOutsideHyderabad ? ' (Outside Area)' : ''}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    final bool isSelected = _selectedLabel == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedLabel = label;
        });
      },
      selectedColor: bandiwalaYellow.withOpacity(0.9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _houseNoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
