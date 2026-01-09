import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'login_page.dart'; // ✅ Import LoginPage
import 'orders.dart';
import 'wishlist.dart';
import 'saved_addresses.dart';
import 'terms_conditions.dart';
import 'cancellation_policy.dart';
import 'refund_policy.dart';
import 'help_support.dart';

const Color kBandiwalaYellow = Color(0xFFFFC107);

class SettingsScreen extends StatefulWidget {
  final String? phoneNumber;
  const SettingsScreen({super.key, this.phoneNumber});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _totalOrders = 0;
  bool _isLoading = true;
  String _displayNumber = '';
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
  }

  // ✅ NEW: Check if user is guest
  Future<void> _checkGuestStatus() async {
    _isGuest = widget.phoneNumber == 'GUEST';

    if (_isGuest) {
      // Show guest login prompt after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showGuestLoginPrompt();
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _displayNumber = 'Guest';
        });
      }
    } else {
      await _initializeData();
    }
  }

  // ✅ NEW: Show dialog for guest users
  void _showGuestLoginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.login, color: kBandiwalaYellow, size: 28),
            SizedBox(width: 12),
            Text(
              'Login Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Please login to access your account settings, orders, and saved addresses.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text(
              'Go Back',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Login Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeData() async {
    await _loadOrderCount();
    _updateDisplayNumber();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDisplayNumber() {
    final phone = widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
    _displayNumber = phone?.replaceAll('+91', '') ?? '';
  }

  Future<void> _loadOrderCount() async {
    try {
      final userPhone = widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
      if (userPhone == null || userPhone == 'GUEST') return;

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customerPhone', isEqualTo: userPhone)
          .get();

      if (mounted) {
        setState(() {
          _totalOrders = ordersSnapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading order count: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
  }

  // ✅ NEW: Show login prompt for guest users trying to access features
  void _showFeatureLockedForGuest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: kBandiwalaYellow, size: 24),
            SizedBox(width: 12),
            Text('Login Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Please login to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToOrders() {
    if (_isGuest) {
      _showFeatureLockedForGuest();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersPage()),
    );
  }

  void _navigateToSavedAddresses() {
    if (_isGuest) {
      _showFeatureLockedForGuest();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedAddressesPage()),
    );
  }

  void _navigateToWishlist() {
    if (_isGuest) {
      _showFeatureLockedForGuest();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WishlistPage()),
    );
  }

  void _navigateToTermsConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsPage()),
    );
  }

  void _navigateToCancellationPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CancellationPolicyPage()),
    );
  }

  void _navigateToRefundPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RefundPolicyPage()),
    );
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kBandiwalaYellow),
        ),
      )
          : RefreshIndicator(
        onRefresh: _initializeData,
        color: kBandiwalaYellow,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildGreetingSection(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Orders',
                        _totalOrders.toString(),
                        Icons.shopping_bag_outlined,
                        onTap: _navigateToOrders,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Wallet',
                        '₹0',
                        Icons.account_balance_wallet_outlined,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _buildMenuSection(),
              const SizedBox(height: 16),
              _buildLogoutButton(),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isGuest ? 'Hello Guest' : 'Hello',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: kBandiwalaYellow,
            letterSpacing: 0.5,
          ),
        ),
        if (!_isGuest) ...[
          const SizedBox(height: 4),
          Text(
            _displayNumber.isNotEmpty ? _displayNumber : 'Guest',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Icon(icon, size: 28, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  onTap: _navigateToSavedAddresses,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Wishlist',
                  onTap: _navigateToWishlist,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: _navigateToTermsConditions,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.cancel_outlined,
                  title: 'Cancellation Policy',
                  onTap: _navigateToCancellationPolicy,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Refund Policy',
                  onTap: _navigateToRefundPolicy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: _buildHelpSupportItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSupportItem() {
    return InkWell(
      onTap: _navigateToHelpSupport,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.headset_mic_outlined, size: 22, color: Colors.black87),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Get assistance anytime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _isGuest
              ? () {
            // For guest, redirect to login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          }
              : _logout,
          icon: Icon(
            _isGuest ? Icons.login : Icons.logout,
            color: _isGuest ? kBandiwalaYellow : Colors.redAccent,
            size: 20,
          ),
          label: Text(
            _isGuest ? 'Login' : 'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isGuest ? kBandiwalaYellow : Colors.redAccent,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isGuest ? kBandiwalaYellow : Colors.redAccent,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
