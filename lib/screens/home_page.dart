// home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'orders.dart';
import 'bottom_navigation.dart';
import 'top_bar.dart';
import 'vendor_items_page.dart';
import 'cart_screen.dart';
import 'scrolling_announcement.dart';
import 'promotional.dart';
import 'location_picker_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

bool _vendorServesZone(Map<String, dynamic> data, String zone) {
  final zoneLower = zone.toLowerCase().trim();
  final addressField = data['address'];
  if (addressField is String && addressField.isNotEmpty) {
    final parts = addressField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p)))
      return true;
  }
  final locationsField = data['locations'];
  if (locationsField is List) {
    final locs = locationsField.map((e) => e.toString().trim().toLowerCase());
    if (locs.any((l) => l.contains(zoneLower) || zoneLower.contains(l)))
      return true;
  } else if (locationsField is String && locationsField.isNotEmpty) {
    final parts = locationsField.split(',').map((p) => p.trim().toLowerCase());
    if (parts.any((p) => p.contains(zoneLower) || zoneLower.contains(p)))
      return true;
  }
  return false;
}

// ─── Active Order Status Bar ──────────────────────────────────────────────────

// ✅ Simplified config — colour is now always yellow/black, only text & icon vary
class _StatusConfig {
  final String label;
  final String subtitle;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

_StatusConfig _resolveStatusConfig(String status) {
  switch (status) {
    case 'order_created':
      return const _StatusConfig(
        label: 'Order Created',
        subtitle: 'Your order has been placed',
        icon: Icons.check_circle_rounded,
      );
    case 'confirmed':
      return const _StatusConfig(
        label: 'Order Confirmed',
        subtitle: 'Your order will soon be prepared',
        icon: Icons.check_circle_rounded,
      );
    case 'preparing':
      return const _StatusConfig(
        label: 'Being Prepared',
        subtitle: 'Your food is being cooked',
        icon: Icons.restaurant_rounded,
      );
    case 'accepted':
      return const _StatusConfig(
        label: 'Order Accepted',
        subtitle: 'Vendor is getting ready',
        icon: Icons.thumb_up_rounded,
      );
    case 'ready':
      return const _StatusConfig(
        label: 'Order Ready',
        subtitle: 'Out for delivery soon',
        icon: Icons.delivery_dining_rounded,
      );
    case 'out_for_delivery':
      return const _StatusConfig(
        label: 'Out for Delivery',
        subtitle: 'Your order is on the way',
        icon: Icons.two_wheeler_rounded,
      );
    case 'delivered':
      return const _StatusConfig(
        label: 'Delivered',
        subtitle: 'Your order has been delivered',
        icon: Icons.done_all_rounded,
      );
    case 'completed':
      return const _StatusConfig(
        label: 'Completed',
        subtitle: 'Order completed successfully',
        icon: Icons.celebration_rounded,
      );
    case 'cancelled':
      return const _StatusConfig(
        label: 'Cancelled',
        subtitle: 'Order has been cancelled',
        icon: Icons.cancel_rounded,
      );
    default:
      return const _StatusConfig(
        label: 'Order Processing',
        subtitle: 'Waiting for update…',
        icon: Icons.hourglass_top_rounded,
      );
  }
}

// ── Pulsing icon ──────────────────────────────────────────────────────────────

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  const _PulseIcon({required this.icon});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      // ✅ Always black icon on yellow background
      child: Icon(widget.icon, size: 22, color: Colors.black87),
    );
  }
}

// ── Order status pill ─────────────────────────────────────────────────────────

class _OrderStatusBarContent extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onViewTap;
  final VoidCallback onDismiss;

  const _OrderStatusBarContent({
    required this.orderData,
    required this.onViewTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final status = (orderData['status'] ?? 'confirmed')
        .toString()
        .toLowerCase();
    final orderId = (orderData['orderId'] ?? '').toString();
    final shortId = orderId.length > 8
        ? orderId.substring(orderId.length - 8)
        : orderId;
    final grandTotal = (orderData['grandTotal'] ?? 0.0) as num;
    final paymentMethod = (orderData['paymentMethod'] ?? '')
        .toString()
        .toLowerCase();

    final cfg = _resolveStatusConfig(status);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        // ✅ Yellow background for all statuses
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withOpacity(0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.black.withOpacity(0.06),
          highlightColor: Colors.black.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Pulsing icon ────────────────────────────────────────
                _PulseIcon(icon: cfg.icon),
                const SizedBox(width: 10),

                // ── Text block ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label + order ID chip
                      Row(
                        children: [
                          Text(
                            cfg.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$shortId',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Subtitle + dot + amount + COD
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cfg.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black87.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (paymentMethod == 'cod') ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Dismiss button ──────────────────────────────────────
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ActiveOrderBar (stream + slide animation) ─────────────────────────────────

class ActiveOrderBar extends StatefulWidget {
  final VoidCallback onViewTap;
  const ActiveOrderBar({super.key, required this.onViewTap});

  @override
  State<ActiveOrderBar> createState() => _ActiveOrderBarState();
}

class _ActiveOrderBarState extends State<ActiveOrderBar>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';
    if (phone.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerPhone', isEqualTo: phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aT = (a.data() as Map)['timestamp'] as Timestamp?;
            final bT = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aT == null || bT == null) return 0;
            return bT.compareTo(aT);
          });

        Map<String, dynamic>? activeOrder;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status != 'completed' && status != 'cancelled') {
            activeOrder = data;
            break;
          }
        }

        if (activeOrder == null) return const SizedBox.shrink();

        return SlideTransition(
          position: _slideAnim,
          child: _OrderStatusBarContent(
            orderData: activeOrder,
            onViewTap: widget.onViewTap,
            onDismiss: _dismiss,
          ),
        );
      },
    );
  }
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
  bool _loadingSavedLocation = true;

  @override
  void initState() {
    super.initState();
    _loadLastUsedLocation();
  }

  Future<void> _loadLastUsedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('last_used_location');
      if (mounted) {
        setState(() {
          if (saved != null) {
            _activeAddress = SavedLocation.fromJson(jsonDecode(saved));
          }
          _loadingSavedLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading last used location: $e');
      if (mounted) setState(() => _loadingSavedLocation = false);
    }
  }

  Future<void> _saveLastUsedLocation(SavedLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_used_location', jsonEncode(loc.toJson()));
    } catch (e) {
      debugPrint('Error saving last used location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        phoneNumber: widget.phoneNumber,
        activeAddress: _activeAddress,
        initiallyLoading: _loadingSavedLocation,
        onAddressChanged: (loc) {
          setState(() => _activeAddress = loc);
          _saveLastUsedLocation(loc);
        },
      ),
      CartScreen(
        deliveryAddress: _activeAddress,
        onBackToHome: () => setState(() => _currentIndex = 0),
      ),
      const OrdersPage(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentIndex != 0) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActiveOrderBar(onViewTap: () => setState(() => _currentIndex = 2)),
            BandiwalaBottomNavigation(
              currentIndex: _currentIndex,
              onItemSelected: (idx) => setState(() => _currentIndex = idx),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HomeTab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final String? phoneNumber;
  final SavedLocation? activeAddress;
  final bool initiallyLoading;
  final void Function(SavedLocation) onAddressChanged;

  const _HomeTab({
    this.phoneNumber,
    this.activeAddress,
    this.initiallyLoading = false,
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

  String? _customerName;

  @override
  void initState() {
    super.initState();
    // If we're still waiting for SharedPreferences, don't trigger GPS yet.
    // didUpdateWidget will catch it when initiallyLoading becomes false.
    if (!widget.initiallyLoading) {
      _resolveUserLocation();
    }
    _checkCustomerName();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger resolution if address changed OR if we just finished initial loading
    if (oldWidget.activeAddress != widget.activeAddress ||
        (oldWidget.initiallyLoading && !widget.initiallyLoading)) {
      _resolveUserLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Customer Name ────────────────────────────────────────────────────────

  Future<void> _checkCustomerName() async {
    final phone =
        widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null || phone == 'GUEST') return;

    try {
      // Normalize: always remove +91 for document ID
      final phoneWithoutCode = phone.replaceAll('+91', '');
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(phoneWithoutCode)
          .get();

      final name = doc.data()?['name'] as String? ?? '';
      if (mounted) setState(() => _customerName = name);

      if (name.isEmpty && mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showNamePrompt(phone);
        });
      }
    } catch (e) {
      debugPrint('Name check error: $e');
    }
  }

  void _showNamePrompt(String phone) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.waving_hand_outlined, color: bandiwalaYellow, size: 26),
            SizedBox(width: 10),
            Text(
              "What's your name?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Help us personalise your experience!',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                // Normalize: always remove +91 for document ID
                final phoneWithoutCode = phone.replaceAll('+91', '');
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(phoneWithoutCode)
                    .set({
                      'name': name,
                      'phone': phone,
                    }, SetOptions(merge: true));
                if (mounted) setState(() => _customerName = name);
              } catch (e) {
                debugPrint('Save name error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  bool _isResolvingLocation = false;

  Future<void> _resolveUserLocation() async {
    if (_isResolvingLocation) return;
    setState(() => _isResolvingLocation = true);

    try {
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
      if (zone == null) _logUnavailableLocation(lat, lng);
    } catch (e) {
      debugPrint('General resolution error: $e');
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
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
      if (_matchedZone != null && !_vendorServesZone(data, _matchedZone!))
        continue;

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

    final result = vendorsMap.values.toList()
      ..sort((a, b) {
        if (a.isAvailable == b.isAvailable) return 0;
        return a.isAvailable ? -1 : 1;
      });
    return result;
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ScrollingAnnouncement(),
            ),
            Expanded(
              child: widget.initiallyLoading || !_locationChecked
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
              "We're not here yet!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Bandiwala hasn't launched in your area yet. We're expanding fast and will be there soon!",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Vendors near you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            // ── Live badge ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LiveDot(),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_matchedZone != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'in $_matchedZone',
                  style: TextStyle(
                    fontSize: 12,
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

// ─── Live Dot (pulsing green circle for real-time indicator) ─────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          shape: BoxShape.circle,
        ),
      ),
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
  final String vendorId, vendorName, vendorCategory, vendorImageUrl, address;
  final double rating;
  final bool isAvailable, isVendorMatch;
  final List<Map<String, dynamic>> matchingItems;

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
        if (snapshot.hasError)
          return const Center(child: Text('Something went wrong'));
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

        final filtered = matchedZone == null
            ? allDocs
            : allDocs
                  .where(
                    (doc) => _vendorServesZone(
                      doc.data() as Map<String, dynamic>,
                      matchedZone!,
                    ),
                  )
                  .toList();

        if (filtered.isEmpty) {
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

        final sortedDocs = [...filtered]
          ..sort((a, b) {
            final aAvail =
                ((a.data() as Map<String, dynamic>)['isAvailable'] ?? true)
                    as bool;
            final bAvail =
                ((b.data() as Map<String, dynamic>)['isAvailable'] ?? true)
                    as bool;
            if (aAvail == bAvail) return 0;
            return aAvail ? -1 : 1;
          });

        return Column(
          children: sortedDocs.map((doc) {
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
  final String vendorId, name, imageUrl, address, category;
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
    return (prefs.getStringList(_key) ?? [])
        .map((json) => WishlistVendor.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<bool> isInWishlist(String vendorId) async =>
      (await getWishlist()).any((v) => v.vendorId == vendorId);

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
  final String vendorId, name, imageUrl, address, category;
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
    await WishlistManager.toggleWishlist(
      WishlistVendor(
        vendorId: widget.vendorId,
        name: widget.name,
        imageUrl: widget.imageUrl,
        address: widget.address,
        category: widget.category,
        rating: widget.rating,
      ),
    );
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
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: 400,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
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
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        if (widget.matchingItems != null &&
                            widget.matchingItems!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.matchingItems!
                                .take(3)
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFC107,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFFFC107,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${item['name']} · ₹${item['price']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      '😴 VENDOR OFFLINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
