import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'settings_screen.dart';
import 'location_picker_page.dart';

class SavedLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? houseNo;
  final String? phone;

  SavedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.houseNo,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'houseNo': houseNo,
    'phone': phone,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    address: json['address'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    houseNo: json['houseNo'],
    phone: json['phone'],
  );
}

class BandiwalaTopBar extends StatefulWidget {
  final String? phoneNumber;
  final Function(bool)? onLocationError;
  final TextEditingController? searchController;

  const BandiwalaTopBar({
    super.key,
    this.phoneNumber,
    this.onLocationError,
    this.searchController,
  });

  static const Color bandiwalaYellow = Color(0xFFFFC107);

  @override
  State<BandiwalaTopBar> createState() => _BandiwalaTopBarState();
}

class _BandiwalaTopBarState extends State<BandiwalaTopBar> {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  // Hyderabad bounds
  static const double hyderabadMinLat = 17.25;
  static const double hyderabadMaxLat = 17.55;
  static const double hyderabadMinLng = 78.25;
  static const double hyderabadMaxLng = 78.65;

  String displayLocation = 'Fetching location...';
  bool isLocationError = false;
  SavedLocation? _currentSavedLocation;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech error: $error');
        setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  Future<void> _initLocation() async {
    try {
      // First try to load saved location
      await _loadSavedLocation();
      if (_currentSavedLocation != null) return;

      // Then try current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => displayLocation = 'Enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() => displayLocation = 'Location permissions denied');
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => displayLocation = 'Location permission needed');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final pos = LatLng(position.latitude, position.longitude);
      await _updatePlaceInfo(pos);
    } catch (e) {
      setState(() {
        displayLocation = 'Unable to fetch location';
      });
    }
  }

  bool _isInHyderabad(double lat, double lng) {
    return lat >= hyderabadMinLat &&
        lat <= hyderabadMaxLat &&
        lng >= hyderabadMinLng &&
        lng <= hyderabadMaxLng;
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
        ].where((part) => part != null && part.trim().isNotEmpty).toList();

        String? placeName = locationParts.isNotEmpty
            ? locationParts.first
            : 'Current Location';

        if (_isInHyderabad(position.latitude, position.longitude)) {
          setState(() {
            displayLocation = placeName!;
            isLocationError = false;
          });
          widget.onLocationError?.call(false);
        } else {
          setState(() {
            displayLocation = placeName!;
            isLocationError = true;
          });
          widget.onLocationError?.call(true);
        }
      }
    } catch (e) {
      setState(() {
        displayLocation = 'Current Location';
      });
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('saved_locations') ?? [];
      if (locationsJson.isNotEmpty) {
        final location = SavedLocation.fromJson(
          jsonDecode(locationsJson.first),
        );
        setState(() {
          _currentSavedLocation = location;
          displayLocation = location.address;
          isLocationError = false;
        });
        widget.onLocationError?.call(false);
      }
    } catch (e) {
      debugPrint('Error loading saved location: $e');
    }
  }

  Future<void> _showLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(),
      ),
    );

    if (result != null && result is SavedLocation) {
      setState(() {
        _currentSavedLocation = result;
        displayLocation = result.address;
        isLocationError = false;
      });
      widget.onLocationError?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = isLocationError
        ? 'Currently serving only Hyderabad'
        : displayLocation;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                isLocationError ? Icons.error_outline : Icons.location_on_outlined,
                color: isLocationError ? Colors.red : Colors.black87,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deliver to',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
                                color: isLocationError ? Colors.red : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(phoneNumber: widget.phoneNumber),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: widget.searchController,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search street food, stalls...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10),
              InkWell(
                onTap: _isListening ? _stopListening : _startListening,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: bandiwalaYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic_none,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startListening() async {
    if (!_speechEnabled || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            if (result.recognizedWords.isNotEmpty) {
              widget.searchController?.text = result.recognizedWords;
            }
          });
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_IN',
        cancelOnError: true,
      );
      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Speech listen error: $e');
      setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
