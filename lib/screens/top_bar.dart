import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'settings_screen.dart';
import 'location_picker_page.dart';

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

class _BandiwalaTopBarState extends State<BandiwalaTopBar>
    with WidgetsBindingObserver {
  static const Color bandiwalaYellow = Color(0xFFFFC107);

  // Hyderabad bounds
  static const double hyderabadMinLat = 17.25;
  static const double hyderabadMaxLat = 17.55;
  static const double hyderabadMinLng = 78.25;
  static const double hyderabadMaxLng = 78.65;

  String displayLocation = 'Fetching location...';
  bool isLocationError = false;
  Position? _currentPosition;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  double _walletBalance = 0.0;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _startLocationUpdates();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startLocationUpdates();
      _loadWalletBalance();
    }
  }

  // ✅ Load wallet balance from SharedPreferences
  Future<void> _loadWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getDouble('wallet_balance') ?? 0.0;
      if (mounted) {
        setState(() => _walletBalance = balance);
      }
    } catch (e) {
      debugPrint('Error loading wallet balance: $e');
    }
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

  Future<void> _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          displayLocation = 'Enable location services';
          isLocationError = true;
        });
        widget.onLocationError?.call(true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          displayLocation = 'Location permissions denied';
          isLocationError = true;
        });
        widget.onLocationError?.call(true);
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            displayLocation = 'Location permission needed';
            isLocationError = true;
          });
          widget.onLocationError?.call(true);
          return;
        }
      }

      await _getCurrentLocationOnce();

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      await _positionStreamSubscription?.cancel();

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
                (Position position) {
              _currentPosition = position;
              _updateLocationDisplay(position);
            },
            onError: (error) {
              debugPrint('Location stream error: $error');
              setState(() {
                displayLocation = 'Location error';
                isLocationError = true;
              });
            },
          );
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      setState(() {
        displayLocation = 'Unable to get location';
        isLocationError = true;
      });
      widget.onLocationError?.call(true);
    }
  }

  Future<void> _getCurrentLocationOnce() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      await _updateLocationDisplay(position);
    } catch (e) {
      debugPrint('Error getting initial location: $e');
      setState(() => displayLocation = 'Getting location...');
    }
  }

  Future<void> _updateLocationDisplay(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;

        List<String> locationParts = [
          place.subLocality,
          place.locality,
          place.street,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => part!)
            .toList();

        String placeName = locationParts.isNotEmpty
            ? locationParts.first
            : 'Current Location';

        final isInServiceArea =
        _isInHyderabad(position.latitude, position.longitude);

        setState(() {
          displayLocation = placeName;
          isLocationError = !isInServiceArea;
        });

        widget.onLocationError?.call(!isInServiceArea);
      }
    } catch (e) {
      debugPrint('Error updating location display: $e');
      if (mounted) {
        setState(() => displayLocation = 'Current Location');
      }
    }
  }

  bool _isInHyderabad(double lat, double lng) {
    return lat >= hyderabadMinLat &&
        lat <= hyderabadMaxLat &&
        lng >= hyderabadMinLng &&
        lng <= hyderabadMaxLng;
  }

  Future<void> _showLocationPicker() async {
    final result = await Navigator.push<SavedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerPage(),
      ),
    );

    if (result != null) {
      _startLocationUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved! Showing live GPS position'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
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
                isLocationError
                    ? Icons.error_outline
                    : Icons.location_on_outlined,
                color: isLocationError ? Colors.red : bandiwalaYellow, // ✅ Changed to yellow
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: bandiwalaYellow, // ✅ Changed to yellow
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 9,
                            color: bandiwalaYellow, // ✅ Changed to yellow
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                color: isLocationError ? Colors.red : null,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Wallet button with balance
              InkWell(
                onTap: () {
                  // Navigate to wallet screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wallet feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  MaterialPageRoute(
                    builder: (_) =>
                        SettingsScreen(phoneNumber: widget.phoneNumber),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(Icons.person_outline, color: Colors.black87),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: widget.searchController,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search street food, stalls...',
                            hintStyle:
                            TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
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
}
