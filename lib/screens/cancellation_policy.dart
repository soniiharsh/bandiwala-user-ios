import 'package:flutter/material.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class CancellationPolicyPage extends StatelessWidget {
  const CancellationPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Cancellation Policy',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 64,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Order Cancellation Policy',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: January 5, 2026',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Content Sections
            _buildSection(
              title: 'Cancellation by User',
              icon: Icons.person_off_outlined,
              children: [
                _buildSubSection(
                  title: '1. Before Merchant Confirms',
                  content: [
                    '• You can cancel for free',
                    '• Full refund issued within 24 hours',
                    '• No cancellation charges applied',
                  ],
                ),
                _buildSubSection(
                  title: '2. After Merchant Confirms (Before Dispatch)',
                  content: [
                    '• Cancellation fee: 10% of order value',
                    '• Minimum cancellation fee: ₹20',
                    '• Remaining amount refunded within 24 hours',
                    '• Some merchants may offer refund without deduction',
                  ],
                ),
                _buildSubSection(
                  title: '3. After Dispatch (Delivery in Progress)',
                  content: [
                    '• Order is non-cancellable',
                    '• If delivery is impossible, contact support',
                    '• Refund may be issued if delivery is refused by recipient',
                  ],
                ),
                _buildSubSection(
                  title: '4. After Delivery',
                  content: [
                    '• Order cannot be cancelled',
                    '• For issues with order quality, proceed to refund request',
                    '• Report issues within 2 hours of delivery',
                  ],
                ),
                _buildSubSection(
                  title: '5. Promo Code Orders',
                  content: [
                    '• Cancelled before merchant confirms: Full refund + promo code remains valid',
                    '• Cancelled after merchant confirms: Deduction applied only to paid amount, not promo value',
                  ],
                ),
              ],
            ),

            _buildSection(
              title: 'Merchant-Initiated Cancellations',
              icon: Icons.store_outlined,
              children: [
                _buildInfoCard(
                  'Merchants may cancel orders if:',
                  [
                    '✓ Items are unexpectedly unavailable',
                    '✓ Order volume exceeds capacity',
                    '✓ Delivery location is outside service area',
                    '✓ Customer uses address outside serviceable zone',
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  'Refund Policy',
                  'Full refund issued immediately and processed automatically',
                ),
              ],
            ),

            _buildSection(
              title: 'BandiWala-Initiated Cancellations',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                _buildInfoCard(
                  'BandiWala may cancel orders due to:',
                  [
                    '• Fraud detection',
                    '• Payment failure',
                    '• Merchant account suspended',
                    '• Delivery partner unavailability',
                    '• Force majeure (earthquakes, floods, etc.)',
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  'Refund Policy',
                  'Full refund issued immediately to original payment method',
                ),
              ],
            ),

            _buildSection(
              title: 'How to Cancel Your Order',
              icon: Icons.help_outline,
              children: [
                _buildStepCard(1, 'Open Your Order', 'Go to "Order History" in the app'),
                _buildStepCard(2, 'Select Order', 'Tap on the order you want to cancel'),
                _buildStepCard(3, 'Cancel Order', 'Click "Cancel Order" button'),
                _buildStepCard(4, 'Confirm', 'Select reason and confirm cancellation'),
                const SizedBox(height: 12),
                _buildWarningBox(
                  'Important',
                  'Cancellation charges may apply based on order status',
                ),
              ],
            ),

            _buildSection(
              title: 'Cancellation Timeline',
              icon: Icons.access_time,
              children: [
                _buildTimelineItem(
                  'Order Placed',
                  'Free cancellation available',
                  true,
                ),
                _buildTimelineItem(
                  'Merchant Confirms',
                  '10% cancellation fee applies (Min ₹20)',
                  true,
                ),
                _buildTimelineItem(
                  'Order Dispatched',
                  'Non-cancellable',
                  true,
                ),
                _buildTimelineItem(
                  'Order Delivered',
                  'Cannot cancel - Request refund instead',
                  false,
                ),
              ],
            ),

            _buildSection(
              title: 'Important Notes',
              icon: Icons.info_outline,
              children: [
                _buildNoteCard(
                  Icons.timer_outlined,
                  'Processing Time',
                  'Refunds are processed within 24 hours of cancellation approval',
                ),
                _buildNoteCard(
                  Icons.account_balance_wallet_outlined,
                  'Refund Method',
                  'Refund will be credited to your original payment method',
                ),
                _buildNoteCard(
                  Icons.warning_amber_outlined,
                  'Abuse Prevention',
                  'Excessive cancellations may result in account review',
                ),
              ],
            ),

            // Contact Support Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBandiwalaYellow.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      color: kBandiwalaYellow,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team for assistance',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'support@bandiwala.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '+91 7382107075',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBandiwalaYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kBandiwalaYellow, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required List<String> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...content.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              point,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHighlightBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBandiwalaYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBandiwalaYellow.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: kBandiwalaYellow, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kBandiwalaYellow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBandiwalaYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBandiwalaYellow),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: kBandiwalaYellow, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String description, bool showLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: kBandiwalaYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kBandiwalaYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
