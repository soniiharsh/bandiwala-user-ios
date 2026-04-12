import 'package:flutter/material.dart';
import '../core/app_env.dart';

class CancellationPolicyPage extends StatelessWidget {
  const CancellationPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cancellation Policy',
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
              'Order Cancellation Policy',
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
            _buildParagraph(
              'This Cancellation Policy outlines the terms and conditions under which orders placed on the BandiWala platform may be cancelled by users, merchants, or BandiWala itself. Please read this policy carefully to understand your rights and obligations.',
            ),

            _buildHeading('Cancellation by User'),

            _buildParagraph(
              'Users may cancel their orders at various stages of the order process. The cancellation charges and refund terms depend on the stage at which the order is cancelled.',
            ),

            _buildSubHeading('Before Merchant Confirms'),
            _buildParagraph(
              'If you cancel your order before the merchant confirms it, you can cancel the order for free. A full refund will be issued to your original payment method within 24 hours. No cancellation charges will be applied at this stage.',
            ),

            _buildSubHeading('After Merchant Confirms (Before Dispatch)'),
            _buildParagraph(
              'Once the merchant has confirmed your order but before it has been dispatched, a cancellation fee of 10% of the order value will be applied. The minimum cancellation fee is ₹20. The remaining amount will be refunded to your original payment method within 24 hours. Please note that some merchants may offer a full refund without any deduction, depending on their individual policies.',
            ),

            _buildSubHeading('After Dispatch (Delivery in Progress)'),
            _buildParagraph(
              'Once your order has been dispatched and is out for delivery, it becomes non-cancellable. However, if the delivery is impossible due to unforeseen circumstances, you may contact our support team. In cases where delivery is refused by the recipient, a refund may be issued after review.',
            ),

            _buildSubHeading('After Delivery'),
            _buildParagraph(
              'Orders cannot be cancelled after they have been delivered. If you have any issues with the quality or condition of your order, you should proceed to submit a refund request instead. Please note that all issues must be reported within 2 hours of delivery for timely resolution.',
            ),

            _buildSubHeading('Orders with Promo Codes'),
            _buildParagraph(
              'For orders placed using promotional codes or discount coupons, special terms apply. If you cancel the order before the merchant confirms it, you will receive a full refund and your promotional code will remain valid for future use. If you cancel after the merchant confirms the order, the cancellation fee will be applied only to the paid amount, not to the promotional discount value.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Merchant-Initiated Cancellations'),

            _buildParagraph(
              'Merchants reserve the right to cancel orders under certain circumstances. These circumstances include but are not limited to: items being unexpectedly unavailable due to stock issues, order volume exceeding the merchant\'s capacity to fulfill orders in a timely manner, delivery location being outside the merchant\'s service area, or the customer using a delivery address that falls outside the serviceable zone.',
            ),

            _buildParagraph(
              'In the event of a merchant-initiated cancellation, a full refund will be issued immediately to your original payment method. The refund will be processed automatically without any intervention required from your side.',
            ),

            const SizedBox(height: 16),
            _buildHeading('BandiWala-Initiated Cancellations'),

            _buildParagraph(
              'BandiWala may cancel orders in exceptional circumstances to protect the integrity of the platform and ensure a safe transaction environment. Orders may be cancelled due to fraud detection, payment failure or discrepancies, merchant account suspension or termination, unavailability of delivery partners in the area, or force majeure events such as natural disasters, earthquakes, floods, or other events beyond our control.',
            ),

            _buildParagraph(
              'When BandiWala cancels an order, a full refund will be issued immediately to your original payment method. You will be notified via email or in-app notification about the cancellation and the reason for it.',
            ),

            const SizedBox(height: 16),
            _buildHeading('How to Cancel Your Order'),

            _buildParagraph(
              'To cancel your order, follow these steps: First, open the BandiWala app and navigate to "Order History" from the menu. Next, select the specific order you wish to cancel by tapping on it. Once the order details are displayed, you will see a "Cancel Order" button. Click on this button and select the reason for cancellation from the provided options. Finally, confirm your cancellation request.',
            ),

            _buildParagraph(
              'Please note that cancellation charges may apply based on the current status of your order. Make sure to review the cancellation policy details before confirming your cancellation.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Cancellation Timeline and Charges'),

            _buildParagraph(
              'The following timeline explains the cancellation charges at each stage of your order:',
            ),

            _buildParagraph(
              'Order Placed: At this stage, you can cancel your order for free without any charges. Once the merchant confirms your order, a cancellation fee of 10% of the order value (minimum ₹20) will be applicable. After the order is dispatched for delivery, it becomes non-cancellable. Once the order has been delivered, you cannot cancel it and must request a refund instead if there are any issues.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Important Notes'),

            _buildParagraph(
              'All refunds are processed within 24 hours of cancellation approval. The refund will be credited to your original payment method, which may include credit cards, debit cards, UPI, wallets, or net banking. Please note that while we process refunds within 24 hours, it may take 3-7 business days for the amount to reflect in your account, depending on your bank or payment provider.',
            ),

            _buildParagraph(
              'BandiWala monitors cancellation patterns to prevent abuse of the cancellation policy. Excessive or repeated cancellations without valid reasons may result in account review and potential restrictions on future orders. We encourage users to cancel orders only when absolutely necessary.',
            ),

            _buildParagraph(
              'In cases where you experience issues with order quality, missing items, or incorrect deliveries, we recommend using the refund request feature instead of cancellation after delivery. This helps us track issues more effectively and improve service quality.',
            ),

            const SizedBox(height: 24),
            _buildHeading('Contact Support'),

            _buildParagraph(
              'If you need assistance with order cancellations, refunds, or have any questions regarding this policy, please feel free to contact our customer support team. We are here to help you.',
            ),

            _buildParagraph(AppEnv.supportContactShort),

            _buildParagraph(
              'Our support team is available to assist you with any concerns or queries you may have regarding order cancellations and refunds.',
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4),
      ),
    );
  }

  Widget _buildSubHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.6, letterSpacing: 0.2),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
