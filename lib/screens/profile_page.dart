import 'package:BandiWala/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/active_address_provider.dart';
import '../providers/orders_provider.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'wishlist_page.dart';
import 'location_picker_page.dart';
import 'terms_conditions_page.dart';
import 'cancellation_policy_page.dart';
import 'refund_policy_page.dart';
import 'help_support_page.dart';
import '../core/theme/theme.dart';

const Color kBandiwalaYellow = AppColors.primary;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  String _displayNumber = '';
  bool _isGuest = false;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    _isGuest = FirebaseAuth.instance.currentUser == null;

    if (_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGuestLoginPrompt();
      });
    }
    _updateDisplayNumber();
    if (mounted) setState(() => _isLoading = false);
  }

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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Go Back',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
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
    _updateDisplayNumber();
    if (mounted) setState(() => _isLoading = false);
  }

  void _updateDisplayNumber() {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    _displayNumber = phone?.replaceAll('+91', '') ?? '';
  }

  void _showEditNameDialog() {
    final currentName = ref.read(userProvider).valueOrNull?.name ?? '';
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBandiwalaYellow, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              setState(() => _isSavingName = true);
              try {
                await ref.read(userProvider.notifier).updateName(newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Name saved successfully!'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSavingName = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiwalaYellow,
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(userProvider.notifier).logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashPage()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your orders, addresses, and profile data will be lost.\n\nAre you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final phone = user.phoneNumber?.replaceAll('+91', '');

          if (phone != null && phone.isNotEmpty) {
            await ref.read(userProvider.notifier).markDeleted();
          }

          // Delete user from Firebase Auth
          await user.delete();

          // Clear local state
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          await ref.read(cartProvider.notifier).clear();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SplashPage()),
              (route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Authentication Required'),
                content: const Text(
                  'For security reasons, you need to login again before deleting your account.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout(); // Force logout so they have to login again
                    },
                    child: const Text('Login Again'),
                  ),
                ],
              ),
            );
          }
        } else {
          debugPrint('Delete account error: $e');
        }
      } catch (e) {
        debugPrint('Delete account error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showFeatureLockedForGuest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: kBandiwalaYellow, size: 24),
            SizedBox(width: 12),
            Text(
              'Login Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
      MaterialPageRoute(builder: (_) => const OrdersPage()),
    );
  }

  void _navigateToSavedAddresses() {
    if (_isGuest) {
      _showFeatureLockedForGuest();
      return;
    }
    final activeAddr = ref.read(activeAddressProvider);
    Navigator.push<SavedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(activeAddress: activeAddr),
      ),
    ).then((result) {
      if (result != null) {
        ref.read(activeAddressProvider.notifier).setAddress(result);
      }
    });
  }

  void _navigateToWishlist() {
    if (_isGuest) {
      _showFeatureLockedForGuest();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistPage()),
    );
  }

  void _navigateToTermsConditions() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
  );

  void _navigateToCancellationPolicy() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CancellationPolicyPage()),
  );

  void _navigateToRefundPolicy() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const RefundPolicyPage()),
  );

  void _navigateToHelpSupport() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HelpSupportPage()),
  );

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
                              ref
                                      .watch(userOrdersProvider)
                                      .valueOrNull
                                      ?.length
                                      .toString() ??
                                  '—',
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

  // Greeting shows name + edit button
  Widget _buildGreetingSection() {
    final customerName = ref.watch(userProvider).valueOrNull?.name ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Hello',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kBandiwalaYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!_isGuest && customerName.isNotEmpty) ...[
                      const TextSpan(
                        text: ', ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kBandiwalaYellow,
                        ),
                      ),
                      TextSpan(
                        text: customerName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ] else if (_isGuest) ...[
                      const TextSpan(
                        text: ' Guest',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kBandiwalaYellow,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!_isGuest)
              _isSavingName
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBandiwalaYellow,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        customerName.isEmpty
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        color: kBandiwalaYellow,
                        size: 26,
                      ),
                      tooltip: customerName.isEmpty ? 'Add Name' : 'Edit Name',
                      onPressed: _showEditNameDialog,
                    ),
          ],
        ),
        if (!_isGuest) ...[
          const SizedBox(height: 4),
          if (customerName.isEmpty)
            GestureDetector(
              onTap: _showEditNameDialog,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to add your name',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              _displayNumber.isNotEmpty ? _displayNumber : '',
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
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
          if (!_isGuest) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: _buildMenuItem(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                onTap: _deleteAccount,
                isDestructive: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
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
            const Icon(
              Icons.headset_mic_outlined,
              size: 22,
              color: Colors.black87,
            ),
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
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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
              ? () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                )
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
