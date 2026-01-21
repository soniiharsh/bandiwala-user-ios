import 'package:flutter/material.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
                    Icons.description_outlined,
                    size: 64,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Terms & Conditions',
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

            // Introduction Section
            _buildSection(
              title: 'Introduction & Acceptance',
              icon: Icons.handshake_outlined,
              children: [
                _buildTextContent(
                  'These Terms of Service govern your access and use of the BandiWala platform, including our website, mobile application, and related services (collectively, "Platform").',
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  'Agreement',
                  'By downloading, installing, accessing, or using the Platform, you acknowledge that you have read, understood, and agree to be bound by these Terms.',
                ),
              ],
            ),

            // Eligibility & Account Creation
            _buildSection(
              title: 'Eligibility & Account Creation',
              icon: Icons.person_add_outlined,
              children: [
                _buildInfoCard(
                  'Age Requirement',
                  'You must be at least 18 years old or the age of majority in your jurisdiction to use the Platform.',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Account Responsibility',
                  '• You are responsible for maintaining the confidentiality of your login credentials\n• All activities under your account are your responsibility\n• You must provide accurate, current, and complete information\n• You agree to update information promptly if changes occur',
                ),
                const SizedBox(height: 12),
                _buildWarningBox(
                  'Account Suspension/Termination',
                  'BandiWala reserves the right to suspend or terminate your account for violations, fraudulent activity, or legal compliance.',
                ),
              ],
            ),

            // Prohibited Use
            _buildSection(
              title: 'Prohibited Use',
              icon: Icons.block_outlined,
              children: [
                _buildProhibitedCard(
                  '1. Content & Communication Violations',
                  [
                    '• Post obscene, defamatory, or harassing content',
                    '• Make negative statements about BandiWala or merchants',
                    '• Engage in harassment or discrimination',
                    '• Share private information without consent',
                  ],
                ),
                _buildProhibitedCard(
                  '2. Fraudulent Activity',
                  [
                    '• Create fake accounts or impersonate others',
                    '• Commit payment fraud',
                    '• Place orders with no intention to pay',
                    '• Manipulate ratings or reviews',
                    '• Engage in refund fraud or abuse',
                  ],
                ),
                _buildProhibitedCard(
                  '3. Technical Violations',
                  [
                    '• Interfere with Platform infrastructure',
                    '• Gain unauthorized access',
                    '• Use bots, scrapers, or automated tools',
                    '• Circumvent security measures',
                    '• Reverse engineer the application',
                  ],
                ),
              ],
            ),

            // Ordering & Payment Terms
            _buildSection(
              title: 'Ordering & Payment Terms',
              icon: Icons.shopping_cart_outlined,
              children: [
                _buildInfoCard(
                  'Order Placement',
                  '• Clicking "Place Order" authorizes BandiWala to place order on your behalf\n• Merchant may accept or decline at their discretion\n• BandiWala is not party to sale contract\n• Direct payments to merchants are prohibited',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Pricing & Availability',
                  '• Prices subject to change without notice\n• All prices include applicable commissions\n• Technical errors may cause incorrect pricing\n• Merchants may cancel if items unavailable',
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodsCard(),
              ],
            ),

            // Merchant Liability Disclaimer
            _buildSection(
              title: 'Merchant Liability Disclaimer',
              icon: Icons.store_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBandiwalaYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBandiwalaYellow.withOpacity(0.8), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: kBandiwalaYellow, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Critical Disclaimer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'BandiWala does NOT own, sell, or control merchants or their food products.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Merchants are independent third parties responsible for:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Quality and freshness of food', 'Proper food safety and hygiene', 'Menu accuracy and ingredients', 'FSSAI compliance', 'All product warranties']
                          .map((item) => Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.black87)),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  'BandiWala\'s Role',
                  'We act as an intermediary, facilitating transactions between you and merchants. We do not guarantee quality, taste, or safety of food items.',
                ),
              ],
            ),

            // Delivery Services
            _buildSection(
              title: 'Delivery Services',
              icon: Icons.delivery_dining_outlined,
              children: [
                _buildInfoCard(
                  'Delivery Partner Role',
                  '• Delivery partners are independent contractors\n• NOT BandiWala employees\n• Delivery times are estimates\n• Delays may occur due to traffic, weather, etc.',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Delivery Conditions',
                  '• BandiWala not liable for delays or food damage\n• Partners not authorized to modify orders\n• You must ensure safe delivery location\n• Orders must be accepted within specified time',
                ),
                const SizedBox(height: 12),
                _buildWarningBox(
                  'Delivery Disputes',
                  'Report delivery issues within 1 hour with photographic evidence. BandiWala will investigate and may issue refunds at discretion.',
                ),
              ],
            ),

            // Ratings & Reviews
            _buildSection(
              title: 'Ratings, Reviews & Content',
              icon: Icons.star_outline,
              children: [
                _buildInfoCard(
                  'Review Conduct',
                  '✓ Reviews must be honest and based on actual experience\n✓ Only review orders you personally received\n✗ No false claims or fabricated stories\n✗ No promotional content for other platforms\n✗ No personal attacks on merchant staff\n✗ No spam or contact information',
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  'Content Ownership',
                  'By posting content, you grant BandiWala a non-exclusive, worldwide, perpetual license to use and display your content.',
                ),
              ],
            ),

            // Governing Law
            _buildSection(
              title: 'Governing Law & Jurisdiction',
              icon: Icons.account_balance_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                          Icon(Icons.gavel, color: Colors.grey.shade700, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Legal Jurisdiction',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• These Terms are governed by the laws of India',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        '• Subject to Consumer Protection Act 2019',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        '• Disputes subject to Hyderabad, Telangana jurisdiction',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        '• Arbitration for disputes ≥ ₹1 lakh',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Contact Information
            _buildSection(
              title: 'Contact Information',
              icon: Icons.contact_support_outlined,
              children: [
                _buildContactCard('General Inquiries', 'hello@bandiwala.com', Icons.email),
                _buildContactCard('Support', 'support@bandiwala.com', Icons.support_agent),
                _buildContactCard('Privacy Concerns', 'privacy@bandiwala.com', Icons.privacy_tip),
                _buildContactCard('Compliance', 'compliance@bandiwala.com', Icons.verified_user),
                const SizedBox(height: 12),
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
                          Icon(Icons.location_on, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Registered Office',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'P-405, PG Block, VJ Hub\nVNRVJIET, Bachupally\nHyderabad, Telangana - 500090\nIndia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer Note
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
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: kBandiwalaYellow,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thank you for reading our Terms & Conditions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using BandiWala, you agree to these terms',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 BandiWala. All Rights Reserved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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

  // Common Section Builder
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

  Widget _buildTextContent(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade800,
        height: 1.5,
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
          const SizedBox(height: 6),
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
    );
  }

  Widget _buildInfoCard(String title, String content) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildProhibitedCard(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              item,
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

  Widget _buildPaymentMethodsCard() {
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
              Icon(Icons.payment, color: kBandiwalaYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Accepted Payment Methods',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '✓ Credit/Debit Cards\n✓ UPI (Google Pay, PhonePe, Paytm)\n✓ Digital Wallets\n✓ Net Banking',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBandiwalaYellow.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: kBandiwalaYellow, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All transactions in Indian Rupees (INR)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String label, String email, IconData icon) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBandiwalaYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: kBandiwalaYellow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
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
}
