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
  final String? label;

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
  String _selectedLabel = 'Other';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _loadSavedLocations();
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

      await _getCurrentLocation();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Location init error: $e');
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
        String? placeName = place.locality ?? place.subLocality ?? 'Current Location';
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
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        final newPos = LatLng(locations.first.latitude, locations.first.longitude);
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
          place.street,
          place.subLocality,
          place.locality,
        ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        _searchController.text = address.isNotEmpty ? address : 'Selected Location';
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

    if (_houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter house number or landmark')),
      );
      return;
    }

    await _reverseGeocode(_selectedPosition!);

    final location = SavedLocation(
      address: _searchController.text.trim().isEmpty
          ? 'Selected Location'
          : _searchController.text.trim(),
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      houseNo: _houseNoController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
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
    widget.onLocationSelected?.call(location);
    if (mounted) Navigator.pop(context, location);
  }

  Future<void> _handleMapTap(LatLng point) async {
    await _updatePlaceInfo(point);
    setState(() => _selectedPosition = point);
    await _reverseGeocode(point);
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(17.3850, 78.4867),
              initialZoom: 14.0,
              onTap: (tapPosition, point) => _handleMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
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
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
                          color: _isOutsideHyderabad ? Colors.orange.shade400 : bandiwalaYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isOutsideHyderabad ? Colors.orange : bandiwalaYellow).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.my_location, color: Colors.black87, size: 18),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search area or street...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                  ),
                  onSubmitted: _searchLocation,
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  if (_savedLocations.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Saved Addresses',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                          ),
                          const Spacer(),
                          if (_isOutsideHyderabad)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Outside service area',
                                style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _savedLocations.length,
                        itemBuilder: (context, index) {
                          final loc = _savedLocations[index];
                          return Container(
                            width: 240,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _selectSavedLocation(loc),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: bandiwalaYellow,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              loc.label == 'Home' ? Icons.home : loc.label == 'Work' ? Icons.work : Icons.location_on,
                                              color: Colors.black87,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            loc.label ?? 'Other',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (loc.houseNo != null && loc.houseNo!.isNotEmpty)
                                        Text(
                                          loc.houseNo!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        loc.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    const SizedBox(height: 20),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
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
                          decoration: InputDecoration(
                            labelText: 'House No, Landmark *',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: bandiwalaYellow, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone (optional)',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade600),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: bandiwalaYellow, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bandiwalaYellow,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Save & Continue',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final bool isSelected = _selectedLabel == label;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black87 : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedLabel = label),
        selectedColor: bandiwalaYellow,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black87 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
