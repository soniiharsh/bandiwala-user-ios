import 'package:flutter/material.dart';
import '../core/app_env.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0.5,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: January 5, 2026',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Content
            _buildHeading('Introduction and Acceptance'),

            _buildParagraph(
              'These Terms of Service govern your access and use of the BandiWala platform, including our website, mobile application, and all related services collectively referred to as the "Platform". By downloading, installing, accessing, or using the Platform in any manner, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
            ),

            _buildParagraph(
              'If you do not agree with any part of these Terms, you must immediately discontinue use of the Platform. Your continued use of our services constitutes acceptance of these Terms and any subsequent modifications we may make from time to time.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Eligibility and Account Creation'),

            _buildParagraph(
              'To use the BandiWala Platform, you must be at least 18 years of age or have reached the age of majority in your jurisdiction. By creating an account, you represent and warrant that you meet this age requirement and have the legal capacity to enter into a binding agreement.',
            ),

            _buildParagraph(
              'You are responsible for maintaining the confidentiality of your login credentials, including your username and password. All activities that occur under your account are your sole responsibility. You must provide accurate, current, and complete information during the registration process and agree to update this information promptly if any changes occur. Failure to maintain accurate information may result in account suspension or termination.',
            ),

            _buildParagraph(
              'BandiWala reserves the right to suspend or terminate your account at any time for violations of these Terms, fraudulent activity, abuse of the Platform, or for legal compliance purposes. We may also refuse service to anyone for any reason at our sole discretion.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Prohibited Use'),

            _buildSubHeading('Content and Communication Violations'),
            _buildParagraph(
              'You agree not to post, transmit, or share any content that is obscene, defamatory, harassing, threatening, or otherwise objectionable. You may not make false or negative statements about BandiWala, its merchants, or other users. Engaging in harassment, discrimination, or abuse of any kind is strictly prohibited. You may not share private or confidential information about other users without their explicit consent.',
            ),

            _buildSubHeading('Fraudulent Activity'),
            _buildParagraph(
              'Creating fake accounts, impersonating other users or merchants, committing payment fraud, or placing orders with no intention to pay are all strictly forbidden. You may not manipulate ratings, reviews, or feedback in any way. Engaging in refund fraud or abusing the refund system through false claims or excessive requests will result in immediate account termination and potential legal action.',
            ),

            _buildSubHeading('Technical Violations'),
            _buildParagraph(
              'You are prohibited from interfering with the Platform infrastructure, servers, or networks. Attempting to gain unauthorized access to any part of the Platform, other user accounts, or computer systems is illegal and will be prosecuted. The use of bots, scrapers, automated tools, or any technology to access the Platform without permission is forbidden. You may not circumvent security measures, reverse engineer the application, or attempt to extract source code.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Ordering and Payment Terms'),

            _buildParagraph(
              'When you click "Place Order" on the Platform, you authorize BandiWala to place the order with the selected merchant on your behalf. Please note that merchants may accept or decline your order at their sole discretion based on availability, capacity, or other factors. BandiWala is not a party to the sale contract between you and the merchant. We act solely as an intermediary facilitating the transaction.',
            ),

            _buildParagraph(
              'Making direct payments to merchants outside the Platform is strictly prohibited and may result in account suspension. All transactions must be processed through the Platform using approved payment methods.',
            ),

            _buildParagraph(
              'Prices displayed on the Platform are subject to change without prior notice. All prices include applicable platform commissions and fees. In the event of technical errors causing incorrect pricing, merchants or BandiWala reserve the right to cancel orders. Merchants may also cancel orders if items become unavailable after order placement.',
            ),

            _buildParagraph(
              'BandiWala accepts the following payment methods: Credit and Debit Cards issued by recognized banks, UPI services including Google Pay, PhonePe, and Paytm, Digital Wallets, and Net Banking. All transactions are processed in Indian Rupees (INR). Payment information is processed securely through certified payment gateways.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Merchant Liability Disclaimer'),

            _buildParagraph(
              'This is a critical disclaimer that all users must understand: BandiWala does NOT own, sell, operate, or control any merchants or their food products. Merchants are independent third-party businesses who list their products on our Platform.',
            ),

            _buildParagraph(
              'Merchants are solely responsible for the quality and freshness of food they prepare and deliver. They are responsible for maintaining proper food safety and hygiene standards in accordance with local health regulations. Merchants must ensure menu accuracy and provide correct information about ingredients, especially allergens. All merchants must maintain valid FSSAI (Food Safety and Standards Authority of India) licenses and comply with food safety regulations. Any product warranties, guarantees, or claims are the sole responsibility of the merchant.',
            ),

            _buildParagraph(
              'BandiWala acts only as an intermediary platform facilitating transactions between customers and merchants. We do not guarantee the quality, taste, safety, or fitness for consumption of any food items ordered through the Platform. While we encourage merchants to maintain high standards, we cannot be held liable for any issues arising from food quality, preparation, or ingredients.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Delivery Services'),

            _buildParagraph(
              'Delivery partners who fulfill orders placed through BandiWala are independent contractors and NOT employees of BandiWala. They operate as third-party service providers. Delivery times displayed on the Platform are estimates only and may vary based on multiple factors including traffic conditions, weather, merchant preparation time, and delivery partner availability.',
            ),

            _buildParagraph(
              'BandiWala is not liable for delays in delivery or damage to food during transit. Delivery partners are not authorized to modify orders, accept additional payments, or make changes to items. You must ensure that you provide a safe and accessible delivery location with clear instructions if necessary. Orders must be accepted within the specified time frame shown in the app.',
            ),

            _buildParagraph(
              'If you experience delivery issues such as significantly delayed delivery, damaged packaging, or incorrect items delivered, you must report these issues within 1 hour of the scheduled delivery time. Provide clear photographic evidence of the issue. BandiWala will investigate all reports and may issue refunds at our sole discretion based on the severity and validity of the complaint.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Ratings, Reviews, and User Content'),

            _buildParagraph(
              'When you submit ratings and reviews on the Platform, you agree that all reviews must be honest and based on your actual personal experience with the order. You may only review orders that you personally received and consumed. False claims, fabricated stories, or reviews based on second-hand information are prohibited.',
            ),

            _buildParagraph(
              'Your reviews must not contain promotional content for competing platforms or services. Personal attacks on merchant staff, delivery partners, or other users are strictly forbidden. Spam, repetitive content, or inclusion of personal contact information in reviews is not allowed.',
            ),

            _buildParagraph(
              'By posting any content including reviews, photos, or comments on the Platform, you grant BandiWala a non-exclusive, worldwide, perpetual, royalty-free license to use, display, reproduce, modify, and distribute your content in any media format. This helps us improve our services and showcase user experiences. You retain ownership of your content but allow us to use it for operational and promotional purposes.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Governing Law and Jurisdiction'),

            _buildParagraph(
              'These Terms and Conditions are governed by and construed in accordance with the laws of India. All disputes arising from your use of the Platform or these Terms shall be subject to the Consumer Protection Act 2019 and other applicable Indian laws.',
            ),

            _buildParagraph(
              'Any disputes, controversies, or claims arising out of or relating to these Terms shall be subject to the exclusive jurisdiction of the courts located in Hyderabad, Telangana, India. For disputes involving amounts equal to or exceeding ₹1 lakh (one lakh Indian Rupees), the parties agree to submit to arbitration in accordance with the Arbitration and Conciliation Act, 1996.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Limitation of Liability'),

            _buildParagraph(
              'To the maximum extent permitted by law, BandiWala shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the Platform. This includes but is not limited to loss of profits, data, goodwill, or other intangible losses resulting from your use or inability to use the service.',
            ),

            _buildParagraph(
              'Our total liability to you for all claims arising from your use of the Platform shall not exceed the amount you paid to BandiWala in the six months preceding the claim, or ₹1,000, whichever is less.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Modifications to Terms'),

            _buildParagraph(
              'BandiWala reserves the right to modify, update, or change these Terms and Conditions at any time without prior notice. When we make changes, we will update the "Last Updated" date at the top of this document. Continued use of the Platform after any such changes constitutes your acceptance of the new Terms.',
            ),

            _buildParagraph(
              'We encourage you to review these Terms periodically to stay informed about any updates. For significant changes that materially affect your rights, we may provide additional notice through the app or via email.',
            ),

            const SizedBox(height: 24),
            _buildHeading('Contact Information'),

            _buildParagraph(
              'For questions, concerns, or inquiries regarding these Terms and Conditions or any aspect of the BandiWala Platform, please contact us using the information below:',
            ),

            _buildParagraph(AppEnv.termsContactBlock),

            _buildParagraph(
              'Registered Office Address:\nP-405, PG Block, VJ Hub\nVNRVJIET, Bachupally\nHyderabad, Telangana - 500090\nIndia',
            ),

            const SizedBox(height: 24),
            _buildHeading('Acceptance of Terms'),

            _buildParagraph(
              'By using BandiWala, you acknowledge that you have read and understood these Terms and Conditions and agree to be bound by them. Thank you for choosing BandiWala for your food delivery needs.',
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),

            Center(
              child: Text(
                '© 2026 BandiWala. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildSubHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
