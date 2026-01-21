import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  bool _orderTrackingExpanded = false;
  bool _paymentIssueExpanded = false;
  bool _deliveryDelayExpanded = false;
  bool _refundQueryExpanded = false;

  Future<void> _launchWhatsApp() async {
    final phoneNumber = '+917382107075'; // Your customer care number
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=Hi%20BandiWala%20Support,%20I%20need%20help%20with...';

    final Uri url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to phone call
      final phoneUrl = 'tel:$phoneNumber';
      final Uri phoneUri = Uri.parse(phoneUrl);
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.chat, color: kBandiwalaYellow),
            onPressed: _launchWhatsApp,
            tooltip: 'WhatsApp Support',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get Help Fast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check common questions below or chat with our support team',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // FAQ 1: Order Tracking
            _buildFAQCard(
              'How can I track my order?',
              _orderTrackingExpanded,
                  () => setState(() => _orderTrackingExpanded = !_orderTrackingExpanded),
              [
                '1. Go to "My Orders" in the bottom navigation',
                '2. Tap on your active order',
                '3. View real-time tracking with ETA',
                '4. Chat with delivery partner if needed',
                '',
                '📍 Orders update every 2-3 minutes',
              ],
            ),

            const SizedBox(height: 16),

            // FAQ 2: Payment Issues
            _buildFAQCard(
              'What if my payment fails?',
              _paymentIssueExpanded,
                  () => setState(() => _paymentIssueExpanded = !_paymentIssueExpanded),
              [
                '✅ Order is NOT placed if payment fails',
                '✅ No charges deducted from your account',
                '✅ Try again or use different payment method',
                '✅ UPI payments may take 30 seconds to confirm',
                '',
                '💳 Supported methods: UPI, Cards, Wallets, Net Banking',
              ],
            ),

            const SizedBox(height: 16),

            // FAQ 3: Delivery Delays
            _buildFAQCard(
              'Why is my order delayed?',
              _deliveryDelayExpanded,
                  () => setState(() => _deliveryDelayExpanded = !_deliveryDelayExpanded),
              [
                '⏱️ Common reasons:',
                '• High order volume at merchant',
                '• Traffic or weather conditions',
                '• Delivery partner re-routed',
                '• Address verification needed',
                '',
                '🔔 You\'ll get notifications for all updates',
              ],
            ),

            const SizedBox(height: 16),

            // FAQ 4: Refund Queries
            _buildFAQCard(
              'How do I get a refund?',
              _refundQueryExpanded,
                  () => setState(() => _refundQueryExpanded = !_refundQueryExpanded),
              [
                '1. Go to "My Orders" → Select order',
                '2. Tap "Report Issue"',
                '3. Select reason & upload photos',
                '4. Submit within 2 hours of delivery',
                '',
                '⚡ 90% refunds processed within 48 hours',
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: kBandiwalaYellow, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildQuickActionButton(
                    'Track Active Order',
                    Icons.location_on_outlined,
                        () {
                      // Navigate to order tracking
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redirecting to Orders...')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionButton(
                    'Cancel Order',
                    Icons.cancel_outlined,
                        () {
                      // Navigate to order cancellation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Check your active orders to cancel')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionButton(
                    'Request Refund',
                    Icons.account_balance_wallet_outlined,
                        () {
                      // Navigate to refund page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Go to My Orders → Report Issue')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Support Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBandiwalaYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBandiwalaYellow.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Still Need Help?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chat with our support team on WhatsApp\nAvailable 9 AM - 10 PM (Mon-Sat)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _launchWhatsApp,
                      icon: Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text(
                        'Chat on WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBandiwalaYellow,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _launchWhatsApp();
                    },
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 14,
                        color: kBandiwalaYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(
      String question,
      bool isExpanded,
      VoidCallback onTap,
      List<String> answer,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (isExpanded)
                          const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: kBandiwalaYellow,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: answer
                    .map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: kBandiwalaYellow),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
