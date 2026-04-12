import 'package:bandiwala_user/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/active_address_provider.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'wishlist_page.dart';
import 'location_picker_page.dart';
import 'terms_conditions_page.dart';
import 'help_support_page.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';
import '../core/navigation/app_page_route.dart';

const Color kBandiWalaYellow = AppColors.primary;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  String _displayNumber = '';
  bool _isGuest = false;

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
            Icon(Icons.login, color: kBandiWalaYellow, size: 28),
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
                AppPageRoute(
                  type: PageTransitionType.scale,
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiWalaYellow,
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
              borderSide: const BorderSide(color: kBandiWalaYellow, width: 2),
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
              } catch (e) {
                debugPrint('Error updating name: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiWalaYellow,
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
            AppPageRoute(
              type: PageTransitionType.scale,
              builder: (_) => const SplashPage(),
            ),
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
              AppPageRoute(
                type: PageTransitionType.scale,
                builder: (_) => const SplashPage(),
              ),
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
            Icon(Icons.lock_outline, color: kBandiWalaYellow, size: 24),
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
                AppPageRoute(
                  type: PageTransitionType.scale,
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBandiWalaYellow,
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
      AppPageRoute(builder: (_) => const OrdersPage()),
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
      AppPageRoute(
        type: PageTransitionType.slideUp,
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
      AppPageRoute(builder: (_) => const WishlistPage()),
    );
  }

  void _navigateToTermsConditions() => Navigator.push(
    context,
    AppPageRoute(builder: (_) => const TermsConditionsPage()),
  );

  void _navigateToHelpSupport() => Navigator.push(
    context,
    AppPageRoute(builder: (_) => const HelpSupportPage()),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider).valueOrNull;
    final customerName = user?.name ?? 'Set Name';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'My Account',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const ProfilePageSkeleton()
          : RefreshIndicator(
              onRefresh: _initializeData,
              color: kBandiWalaYellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Account'),
                    _buildCardContainer([
                      _buildAccountRow(
                        icon: Icons.edit_outlined,
                        label: 'Name',
                        value: _isGuest ? 'Guest' : customerName,
                        onTap: _isGuest ? null : _showEditNameDialog,
                      ),
                      _buildDivider(),
                      _buildAccountRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: '—', // AppUser doesn't have email in this version
                      ),
                      _buildDivider(),
                      _buildAccountRow(
                        icon: Icons.phone_outlined,
                        label: 'Mobile',
                        value: _isGuest ? '—' : _displayNumber,
                      ),
                    ]),
                    
                    _buildSectionTitle('Food Orders'),
                    _buildCardContainer([
                      _buildMenuRow(
                        icon: Icons.receipt_long_outlined,
                        title: 'Your Orders',
                        onTap: _navigateToOrders,
                      ),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.favorite_border,
                        title: 'Favourite orders',
                        onTap: _navigateToWishlist,
                      ),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.location_on_outlined,
                        title: 'Address book',
                        onTap: _navigateToSavedAddresses,
                      ),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.help_outline,
                        title: 'Online ordering help',
                        onTap: _navigateToHelpSupport,
                      ),
                    ]),

                    _buildSectionTitle('More'),
                    _buildCardContainer([
                      _buildThemeRow(),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.translate,
                        title: 'Choose language',
                        onTap: () {}, // Placeholder
                      ),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: _navigateToTermsConditions,
                      ),
                      _buildDivider(),
                      _buildMenuRow(
                        icon: Icons.feedback_outlined,
                        title: 'Send feedback',
                        onTap: () {}, // Placeholder
                      ),
                    ]),

                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    if (!_isGuest) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _deleteAccount,
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 14, color: cs.primary.withValues(alpha: 0.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeRow() {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isGuest
              ? () => Navigator.pushAndRemoveUntil(
                    context,
                    AppPageRoute(
                      type: PageTransitionType.scale,
                      builder: (_) => const LoginPage(),
                    ),
                    (route) => false,
                  )
              : _logout,
          icon: Icon(
            _isGuest ? Icons.login : Icons.logout,
            color: Colors.black87,
            size: 20,
          ),
          label: Text(
            _isGuest ? 'Login' : 'Logout',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBandiWalaYellow,
            elevation: 2,
            shadowColor: kBandiWalaYellow.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
