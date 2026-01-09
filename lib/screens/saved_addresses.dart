import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'location_picker_page.dart'; // Import your location picker
import 'package:flutter_map/flutter_map.dart';  // ✅ ADD THIS
import 'package:latlong2/latlong.dart';

const kBandiwalaYellow = Color(0xFFFFC107);
const kWhite = Color(0xFFFFFFFF);
const kBorderGrey = Color(0xFFE5E7EB);
const kTextGrey = Color(0xFF6B7280);
const kLightGrey = Color(0xFFF9FAFB);

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('saved_locations') ?? [];
      setState(() {
        _savedLocations = locationsJson
            .map((json) => SavedLocation.fromJson(jsonDecode(json)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Address?'),
          ],
        ),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final locationsJson = prefs.getStringList('saved_locations') ?? [];
        locationsJson.removeAt(index);
        await prefs.setStringList('saved_locations', locationsJson);

        setState(() {
          _savedLocations.removeAt(index);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Address deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editLocation(int index) async {
    final location = _savedLocations[index];

    // Navigate to location picker with pre-filled data
    final result = await Navigator.push<SavedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerEditMode(
          existingLocation: location,
          locationIndex: index,
        ),
      ),
    );

    if (result != null) {
      await _loadSavedLocations(); // Reload all locations
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Address updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  IconData _getLabelIcon(String? label) {
    switch (label) {
      case 'Home':
        return Icons.home;
      case 'Work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  Color _getLabelColor(String? label) {
    switch (label) {
      case 'Home':
        return Colors.blue;
      case 'Work':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGrey,
      appBar: AppBar(
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kWhite,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: kBorderGrey),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: kBandiwalaYellow,
          strokeWidth: 3,
        ),
      )
          : _savedLocations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: kBandiwalaYellow,
        onRefresh: _loadSavedLocations,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _savedLocations.length,
          itemBuilder: (context, index) {
            final location = _savedLocations[index];
            return _buildAddressCard(location, index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<SavedLocation>(
            context,
            MaterialPageRoute(
              builder: (context) => const LocationPickerPage(),
            ),
          );
          if (result != null) {
            await _loadSavedLocations();
          }
        },
        backgroundColor: kBandiwalaYellow,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add_location_alt),
        label: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 80,
              color: kBandiwalaYellow,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Saved Addresses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your delivery addresses\nfor faster checkout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<SavedLocation>(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationPickerPage(),
                ),
              );
              if (result != null) {
                await _loadSavedLocations();
              }
            },
            icon: const Icon(Icons.add_location_alt, color: Colors.black87),
            label: const Text(
              'Add Address',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedLocation location, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getLabelColor(location.label).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getLabelIcon(location.label),
                    color: _getLabelColor(location.label),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.label ?? 'Other',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (location.phone != null && location.phone!.isNotEmpty)
                        Text(
                          location.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editLocation(index),
                  icon: const Icon(Icons.edit_outlined),
                  color: kBandiwalaYellow,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteLocation(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: kBorderGrey),
            const SizedBox(height: 12),

            // House number/Landmark
            if (location.houseNo != null && location.houseNo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.houseNo!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Full address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            // Coordinates (optional, for debugging)
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.map_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: Edit Mode for Location Picker
class LocationPickerEditMode extends StatefulWidget {
  final SavedLocation existingLocation;
  final int locationIndex;

  const LocationPickerEditMode({
    super.key,
    required this.existingLocation,
    required this.locationIndex,
  });

  @override
  State<LocationPickerEditMode> createState() => _LocationPickerEditModeState();
}

class _LocationPickerEditModeState extends State<LocationPickerEditMode> {
  late LatLng _selectedPosition;
  late TextEditingController _searchController;
  late TextEditingController _houseNoController;
  late TextEditingController _phoneController;
  late String _selectedLabel;
  final MapController _mapController = MapController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.existingLocation.latitude,
      widget.existingLocation.longitude,
    );
    _searchController = TextEditingController(text: widget.existingLocation.address);
    _houseNoController = TextEditingController(text: widget.existingLocation.houseNo ?? '');
    _phoneController = TextEditingController(text: widget.existingLocation.phone ?? '');
    _selectedLabel = widget.existingLocation.label ?? 'Other';

    // Move map to existing location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_selectedPosition, 16.0);
    });
  }

  Future<void> _updateLocation() async {
    if (_houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter house number or landmark')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedLocation = SavedLocation(
        address: _searchController.text.trim().isEmpty
            ? 'Selected Location'
            : _searchController.text.trim(),
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        houseNo: _houseNoController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        label: _selectedLabel,
      );

      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('saved_locations') ?? [];

      // Update the location at the specific index
      locationsJson[widget.locationIndex] = jsonEncode(updatedLocation.toJson());
      await prefs.setStringList('saved_locations', locationsJson);

      if (mounted) {
        Navigator.pop(context, updatedLocation);
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Address',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kWhite,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          // Map (same as LocationPickerPage)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 16.0,
              onTap: (tapPosition, point) {
                setState(() => _selectedPosition = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // Bottom form
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.75,
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
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Update Address Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBandiwalaYellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone (optional)',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBandiwalaYellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBandiwalaYellow,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                          : const Text(
                        'Update Address',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
        selectedColor: kBandiwalaYellow,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black87 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
