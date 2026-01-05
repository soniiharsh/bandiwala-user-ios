import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';

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
  String _displayNumber = 'Bandiwala user';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCustomerData();
    _updateDisplayNumber();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDisplayNumber() {
    final phone =
        widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
    _displayNumber = phone?.replaceAll('+91', '') ?? 'Bandiwala user';
  }

  Future<void> _loadCustomerData() async {
    try {
      final userPhone =
          widget.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber;
      if (userPhone == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(userPhone.replaceAll('+91', ''));

      final snapshot = await docRef.get();
      if (snapshot.exists && mounted) {
        setState(() {
          _totalOrders = snapshot['orders'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    }
  }

  Future<void> _logout() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _displayNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      _totalOrders.toString(),
                      Icons.shopping_bag,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _WalletStatCard(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SettingsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: kBandiwalaYellow,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: kBandiwalaYellow),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
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
}

class _WalletStatCard extends StatelessWidget {
  const _WalletStatCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wallet, size: 32, color: kBandiwalaYellow),
            SizedBox(height: 8),
            Text(
              '₹0',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Wallet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Profile'),
        ),
        Divider(height: 1),
        ListTile(
          leading: Icon(Icons.location_on_outlined),
          title: Text('Saved addresses'),
        ),
        Divider(height: 1),
        ListTile(
          leading: Icon(Icons.payment_outlined),
          title: Text('Payment methods'),
        ),
        Divider(height: 1),
        ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Help & support'),
        ),
      ],
    );
  }
}
