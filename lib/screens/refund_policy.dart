import 'package:flutter/material.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Refund Policy',
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
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Refund Policy',
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

            // Refund Eligibility Section
            _buildSection(
              title: 'Refund Eligibility',
              icon: Icons.verified_outlined,
              children: [
                _buildInfoCard(
                  'You can request a refund for:',
                  [
                    '✓ Missing items from your order',
                    '✓ Wrong items delivered',
                    '✓ Food quality issues (spoilt, raw, burnt)',
                    '✓ Significantly different from description',
                  ],
                ),
              ],
            ),

            // How to Request Refund Section
            _buildSection(
              title: 'How to Request a Refund',
              icon: Icons.assignment_outlined,
              children: [
                _buildStepCard(1, 'Open Order History', 'Navigate to your past orders'),
                _buildStepCard(2, 'Select Order', 'Tap on the order with issues'),
                _buildStepCard(3, 'Report Issue', 'Click "Report Issue" or "Request Refund"'),
                _buildStepCard(4, 'Select Reason', 'Choose the reason for refund'),
                _buildStepCard(5, 'Upload Evidence', 'Provide photos (strongly recommended)'),
                _buildStepCard(6, 'Submit Request', 'Submit and wait for review'),
                const SizedBox(height: 12),
                _buildWarningBox(
                  'Important',
                  'Photographic evidence significantly increases approval chances',
                ),
              ],
            ),

            // Timeline Section
            _buildSection(
              title: 'Refund Timeline',
              icon: Icons.schedule_outlined,
              children: [
                _buildTimelineBox('Request Window', 'Within 2 hours of delivery', Icons.timer),
                _buildTimelineBox('Review Period', 'BandiWala reviews within 48 hours', Icons.search),
                _buildTimelineBox('Decision', 'Communicated within 72 hours', Icons.notification_important),
                _buildTimelineBox('Processing', 'Refund processed within 5-7 business days', Icons.account_balance),
              ],
            ),

            // Refund Decisions Section
            _buildSection(
              title: 'Refund Decisions',
              icon: Icons.gavel_outlined,
              children: [
                _buildSubSection(
                  title: 'Approved Refunds',
                  icon: Icons.check_circle,
                  points: [
                    '• Full order refund for major issues',
                    '• Partial refund for specific items',
                    '• Option to reorder at no extra cost',
                  ],
                ),
                const SizedBox(height: 12),
                _buildSubSection(
                  title: 'Approval Conditions',
                  icon: Icons.done_all,
                  points: [
                    '• Clear photographic evidence provided',
                    '• Reasonable and valid claim',
                    '• First-time issue with merchant',
                    '• Order value ≥ ₹200 (for full refunds)',
                  ],
                ),
              ],
            ),

            // Rejected Refunds Section
            _buildSection(
              title: 'Refund Rejection Reasons',
              icon: Icons.cancel_outlined,
              children: [
                _buildRejectionCard('Insufficient or no evidence', Icons.photo_camera_outlined),
                _buildRejectionCard('Claim made beyond 24 hours', Icons.access_time),
                _buildRejectionCard('Customer at fault (ordered wrong item)', Icons.person_outlined),
                _buildRejectionCard('Multiple refund requests (abuse)', Icons.warning_amber),
                _buildRejectionCard('Food allergies (if clearly mentioned)', Icons.info_outlined),
                _buildRejectionCard('Reasonable consumption time passed', Icons.timer_off),
              ],
            ),

            // Refund Methods Section
            _buildSection(
              title: 'Refund Methods & Processing Time',
              icon: Icons.payment_outlined,
              children: [
                _buildRefundMethodTable(),
              ],
            ),

            // Partial Refunds Section
            _buildSection(
              title: 'Partial Refunds',
              icon: Icons.calculate_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Calculation Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'If only some items have issues:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Refund calculated based on item price only',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBandiwalaYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBandiwalaYellow.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Example:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Order Total: ₹500\nIssue Item: ₹150\nRefund Amount: ₹150',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Non-Refundable Section
            _buildSection(
              title: 'Non-Refundable Situations',
              icon: Icons.block_outlined,
              children: [
                _buildNonRefundableCard('Delivery fees (if delivery completed)', Icons.delivery_dining),
                _buildNonRefundableCard('Packing charges', Icons.inventory_2_outlined),
                _buildNonRefundableCard('Items customer ate/consumed partially', Icons.restaurant),
                _buildNonRefundableCard('Special instructions changed after confirmation', Icons.edit_note),
                _buildNonRefundableCard('Self-pickup orders (customer responsibility)', Icons.storefront),
                _buildNonRefundableCard('Offers/discounts already redeemed', Icons.local_offer),
              ],
            ),

            // Abuse Prevention Section
            _buildSection(
              title: 'Refund Abuse Prevention',
              icon: Icons.security_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBandiwalaYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBandiwalaYellow, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: kBandiwalaYellow, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Account Actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAbuseItem('3+ refunds per month', 'Account review'),
                      _buildAbuseItem('Suspected fraudulent claims', 'Account suspension'),
                      _buildAbuseItem('Pattern of false claims', 'Permanent ban'),
                    ],
                  ),
                ),
              ],
            ),

            // Disputes & Appeals Section
            _buildSection(
              title: 'Disputes & Appeals',
              icon: Icons.gavel,
              children: [
                _buildInfoCard(
                  'If you disagree with a refund decision:',
                  [
                    '1. Contact support within 24 hours',
                    '2. Provide additional evidence or clarification',
                    '3. Final decision made within 48 hours',
                    '4. Escalation to senior team available for major disputes',
                  ],
                ),
              ],
            ),

            // Important Notes
            _buildSection(
              title: 'Important Notes',
              icon: Icons.info_outline,
              children: [
                _buildNoteCard(
                  Icons.camera_alt_outlined,
                  'Photographic Evidence',
                  'Always provide clear photos of issues for faster approval',
                ),
                _buildNoteCard(
                  Icons.timer_outlined,
                  'Time Limit',
                  'Report issues within 2 hours of delivery for eligibility',
                ),
                _buildNoteCard(
                  Icons.account_balance_wallet_outlined,
                  'Refund Tracking',
                  'Track refund status in Order History > Refund Status',
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
                    'Need Help with Refunds?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to assist you',
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '9 AM - 10 PM (Mon-Sat)',
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

  Widget _buildTimelineBox(String title, String description, IconData icon) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kBandiwalaYellow, size: 24),
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
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required IconData icon,
    required List<String> points,
  }) {
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
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
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

  Widget _buildRejectionCard(String reason, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundMethodTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildTableRow('Payment Method', 'Refund Method', 'Time', isHeader: true),
          _buildTableRow('Credit/Debit Card', 'Card credit', '5-10 days'),
          _buildTableRow('UPI', 'UPI reversal', '1-2 hours'),
          _buildTableRow('Wallet', 'Wallet credit', 'Instant'),
          _buildTableRow('Net Banking', 'Bank account', '3-7 days'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade100 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              col1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                color: isHeader ? Colors.black87 : Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              col2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                color: isHeader ? Colors.black87 : Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              col3,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                color: isHeader ? Colors.black87 : Colors.grey.shade800,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonRefundableCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.block, color: Colors.grey.shade600, size: 18),
        ],
      ),
    );
  }

  Widget _buildAbuseItem(String trigger, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                children: [
                  TextSpan(
                    text: trigger,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' → '),
                  TextSpan(
                    text: action,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
