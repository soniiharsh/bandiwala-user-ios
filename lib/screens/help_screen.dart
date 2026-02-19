import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // WhatsApp Support Number
  static const String whatsappNumber =
      '+917382107075'; // Replace with your number
  static const String supportEmail = 'support@bandiwala.in';

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$whatsappNumber?text=Hi, I need help with my order',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUrl = Uri.parse(
      'mailto:$supportEmail?subject=Support Request',
    );

    try {
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email app found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'We\'re here to help! Find answers to common questions or get in touch with us.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FAQ Section Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // FAQ Items
                    const _FAQItem(
                      question: 'How do I track my order?',
                      answer:
                          'Go to Orders tab → tap any order to see live tracking with delivery partner location.',
                    ),
                    const _FAQItem(
                      question: 'How to contact delivery partner?',
                      answer:
                          'Tap "Call Rider" button during delivery from Orders screen. Available 24/7.',
                    ),
                    const _FAQItem(
                      question: 'Can I change Delivery Address',
                      answer:
                          'Edit address before confirming order in Checkout screen. After confirmation, contact support.',
                    ),
                    const _FAQItem(
                      question: 'How can I cancel my order?',
                      answer:
                          'Cancel within 2 minutes of placing. No refunds after vendor starts preparation.',
                    ),
                    const _FAQItem(
                      question: 'How do I apply a promo code?',
                      answer:
                          'In cart, tap "Apply Coupon" → select available coupon → discount applied automatically.',
                    ),
                    const _FAQItem(
                      question: 'Can I schedule a delivery?',
                      answer:
                          'Currently we support instant delivery only. Scheduled delivery coming soon!',
                    ),

                    const SizedBox(height: 24),

                    // Contact Us Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            size: 18,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Us',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Can\'t find what you\'re looking for? Reach out to our support team.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // Call Us Card
                    _ContactCard(
                      icon: Icons.phone,
                      iconColor: const Color(0xFFFFC107),
                      title: 'Call Us',
                      subtitle: '7382107075',
                      onTap: () => _launchWhatsApp(context),
                    ),

                    const SizedBox(height: 12),

                    // Email Us Card
                    _ContactCard(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFFFFC107),
                      title: 'Email Us',
                      subtitle: supportEmail,
                      onTap: () => _launchEmail(context),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
