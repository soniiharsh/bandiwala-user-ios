import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'orders_page.dart'; // ← adjust import path as needed

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

  // ─── WhatsApp launcher ─────────────────────────────────────────────────────

  Future<void> _launchWhatsApp({String prefillMessage = ''}) async {
    final phone = '+917382107075';
    final encoded = Uri.encodeComponent(
      prefillMessage.isNotEmpty
          ? prefillMessage
          : 'Hi BandiWala Support, I need help with...',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse('tel:$phone');
      if (await canLaunchUrl(fallback)) await launchUrl(fallback);
    }
  }

  // ─── Navigate to Orders page ───────────────────────────────────────────────

  void _goToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersPage()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: kBandiwalaYellow, size: 20),
            onPressed: () => _launchWhatsApp(),
            tooltip: 'WhatsApp Support',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Compact header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 36,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get Help Fast',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check FAQs or chat with support',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── FAQs ────────────────────────────────────────────────────
            const Text(
              'FAQs',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            _buildCompactFAQ(
              'How can I track my order?',
              _orderTrackingExpanded,
              () => setState(
                () => _orderTrackingExpanded = !_orderTrackingExpanded,
              ),
              [
                '1. Go to "My Orders"',
                '2. Tap on active order',
                '3. View real-time tracking',
                '4. Chat with delivery partner',
              ],
            ),
            const SizedBox(height: 8),

            _buildCompactFAQ(
              'What if my payment fails?',
              _paymentIssueExpanded,
              () => setState(
                () => _paymentIssueExpanded = !_paymentIssueExpanded,
              ),
              [
                '• Order NOT placed if payment fails',
                '• No charges deducted',
                '• Try again or use different method',
                '• UPI may take 30 seconds',
              ],
            ),
            const SizedBox(height: 8),

            _buildCompactFAQ(
              'Why is my order delayed?',
              _deliveryDelayExpanded,
              () => setState(
                () => _deliveryDelayExpanded = !_deliveryDelayExpanded,
              ),
              [
                '• High order volume',
                '• Traffic or weather',
                '• Delivery partner re-routed',
                '• Address verification needed',
              ],
            ),
            const SizedBox(height: 8),

            _buildCompactFAQ(
              'How do I get a refund?',
              _refundQueryExpanded,
              () =>
                  setState(() => _refundQueryExpanded = !_refundQueryExpanded),
              [
                '1. My Orders → Select order',
                '2. Tap "Report Issue"',
                '3. Select reason & upload photos',
                '4. Submit within 2 hours',
              ],
            ),

            const SizedBox(height: 16),

            // ── Quick Actions ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.flash_on,
                        color: kBandiwalaYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Track order → OrdersPage
                  _buildSmallActionButton(
                    'Track Active Order',
                    Icons.location_on_outlined,
                    _goToOrders,
                  ),
                  const SizedBox(height: 6),

                  // Cancel order → WhatsApp with prefill
                  _buildSmallActionButton(
                    'Cancel Order',
                    Icons.cancel_outlined,
                    () => _launchWhatsApp(
                      prefillMessage:
                          'Hi BandiWala Support, I want to cancel my order. Please help.',
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Refund → WhatsApp with prefill
                  _buildSmallActionButton(
                    'Request Refund',
                    Icons.account_balance_wallet_outlined,
                    () => _launchWhatsApp(
                      prefillMessage:
                          'Hi BandiWala Support, I want to request a refund for my recent order. Please help.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Still need help ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBandiwalaYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBandiwalaYellow.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Still Need Help?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat on WhatsApp\n9 AM – 10 PM (Mon–Sat)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchWhatsApp(),
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: const Text(
                        'Chat on WhatsApp',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBandiwalaYellow,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── FAQ tile ─────────────────────────────────────────────────────────────

  Widget _buildCompactFAQ(
    String question,
    bool isExpanded,
    VoidCallback onTap,
    List<String> answer,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: kBandiwalaYellow,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: answer
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Action button ────────────────────────────────────────────────────────

  Widget _buildSmallActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: kBandiwalaYellow, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
