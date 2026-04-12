import 'package:flutter/material.dart';
import '../core/theme/map_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import 'location_picker_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';
import '../core/navigation/app_page_route.dart';

const kBandiWalaYellow = AppColors.primary;

class SavedAddressesPage extends ConsumerStatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  ConsumerState<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends ConsumerState<SavedAddressesPage> {
  bool _isLoading = false;

  SavedAddress _toSavedAddress(SavedAddress a) => a;

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
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
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
        setState(() => _isLoading = true);
        await ref.read(userProvider.notifier).deleteAddress(index);
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
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editLocation(int index, SavedAddress location) async {
    final result = await Navigator.push<SavedAddress>(
      context,
      AppPageRoute(
        type: PageTransitionType.slideUp,
        builder: (context) => LocationPickerEditMode(
          existingLocation: location,
          locationIndex: index,
        ),
      ),
    );

    if (result != null) {
      try {
        await ref.read(userProvider.notifier).updateAddress(index, result);
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
      } catch (e) {
        debugPrint('Error updating location: $e');
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
    final savedAddresses =
        ref.watch(userProvider).valueOrNull?.savedAddresses ?? [];
    final savedLocations = savedAddresses.map(_toSavedAddress).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.cardColor,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: theme.dividerColor),
        ),
      ),
      body: _isLoading
          ? const SavedAddressesSkeleton()
          : savedLocations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedLocations.length,
              itemBuilder: (context, index) {
                return _buildAddressCard(savedLocations[index], index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push<SavedAddress>(
            context,
            AppPageRoute(
              type: PageTransitionType.slideUp,
              builder: (context) => const LocationPickerPage(),
            ),
          );
          // No need to setState — userProvider stream updates automatically
        },
        backgroundColor: kBandiWalaYellow,
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
              color: kBandiWalaYellow.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 80,
              color: kBandiWalaYellow,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Addresses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
              await Navigator.push<SavedAddress>(
                context,
                AppPageRoute(
                  type: PageTransitionType.slideUp,
                  builder: (context) => const LocationPickerPage(),
                ),
              );
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
              backgroundColor: kBandiWalaYellow,
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

  Widget _buildAddressCard(SavedAddress location, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getLabelColor(location.label).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getLabelIcon(location.label),
                color: _getLabelColor(location.label),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location.label ?? 'Other',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (location.address != null &&
                      location.address!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      location.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editLocation(index, location),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: kBandiWalaYellow,
              tooltip: 'Edit',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _deleteLocation(index),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade400,
              tooltip: 'Delete',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: Edit Mode for Location Picker
class LocationPickerEditMode extends ConsumerStatefulWidget {
  final SavedAddress existingLocation;
  final int locationIndex;

  const LocationPickerEditMode({
    super.key,
    required this.existingLocation,
    required this.locationIndex,
  });

  @override
  ConsumerState<LocationPickerEditMode> createState() =>
      _LocationPickerEditModeState();
}

class _LocationPickerEditModeState
    extends ConsumerState<LocationPickerEditMode> {
  late LatLng _selectedPosition;
  late TextEditingController _searchController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _customLabelController;
  late String _selectedLabel;
  GoogleMapController? _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.existingLocation.latitude,
      widget.existingLocation.longitude,
    );
    _searchController = TextEditingController(
      text: widget.existingLocation.geolocation,
    );
    _addressController = TextEditingController(
      text: widget.existingLocation.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingLocation.phone,
    );
    _customLabelController = TextEditingController();

    final label = widget.existingLocation.label ?? 'Other';
    if (label != 'Home' && label != 'Work') {
      _selectedLabel = 'Other';
      _customLabelController.text = label;
    } else {
      _selectedLabel = label;
    }

    // Move map to existing location
    _mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(_selectedPosition, 16.0),
    );
  }

  Future<void> _updateLocation() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter house number or landmark')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedLocation = SavedAddress(
        geolocation: _searchController.text.trim().isEmpty
            ? 'Selected Location'
            : _searchController.text.trim(),
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        label: _selectedLabel == 'Other'
            ? _customLabelController.text.trim()
            : _selectedLabel,
      );

      if (updatedLocation.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number')),
        );
        return;
      }

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Address',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.cardColor,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          // Map (same as LocationPickerPage)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 16.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (isDark) {
                _mapController?.setMapStyle(MapStyles.darkStyle);
              }
              _mapController?.moveCamera(
                CameraUpdate.newLatLngZoom(_selectedPosition, 16.0),
              );
            },
            onTap: (point) {
              setState(() => _selectedPosition = point);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Bottom form
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.75,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
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
                  Text(
                    'Update Address Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address (House No, Building, Area) *',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kBandiWalaYellow,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone *',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kBandiWalaYellow,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedLabel == 'Other') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _customLabelController,
                      decoration: InputDecoration(
                        labelText: 'Custom Label *',
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: kBandiWalaYellow,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBandiWalaYellow,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black87 : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedLabel = label),
        selectedColor: kBandiWalaYellow,
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
    _addressController.dispose();
    _phoneController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }
}
