import 'package:flutter/material.dart';
import '../core/app_env.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Refund Policy',
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
              'Refund Policy',
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
              'This Refund Policy explains the terms and conditions under which customers may request refunds for orders placed through the BandiWala platform. We are committed to ensuring customer satisfaction while maintaining fair practices for all parties involved.',
            ),

            _buildHeading('Refund Eligibility'),

            _buildParagraph(
              'You are eligible to request a refund for your order under the following circumstances: missing items from your order that were paid for but not delivered, wrong items delivered that do not match what you ordered, food quality issues including spoilt food, undercooked or raw food, burnt or overcooked items, or items that are significantly different from their description on the platform.',
            ),

            _buildParagraph(
              'All refund requests must be made within 2 hours of delivery to be considered eligible. Requests made after this time window may not be processed. We strongly recommend providing photographic evidence of the issue to support your claim and expedite the approval process.',
            ),

            const SizedBox(height: 16),
            _buildHeading('How to Request a Refund'),

            _buildParagraph(
              'To request a refund, follow these steps: First, open the BandiWala app and navigate to "Order History" to view your past orders. Select the specific order for which you want to request a refund by tapping on it. Once the order details are displayed, click on the "Report Issue" or "Request Refund" button. Choose the appropriate reason for your refund request from the list of options provided. Upload clear photographic evidence of the issue if possible - this is strongly recommended as it significantly increases the chances of approval. Finally, submit your refund request and wait for our team to review it.',
            ),

            _buildParagraph(
              'Photographic evidence plays a crucial role in the refund approval process. Clear images showing the issue with your order help our team make faster and more accurate decisions. Without proper evidence, your refund request may be rejected.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Refund Timeline and Process'),

            _buildParagraph(
              'The refund process follows a specific timeline to ensure thorough review and fair resolution. The request window is limited to 2 hours from the time of delivery. After you submit your refund request, BandiWala reviews the claim within 48 hours. You will be communicated the decision regarding your refund within 72 hours of submission. If your refund is approved, the amount will be processed within 5 to 7 business days, depending on your original payment method.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Refund Decisions and Approval'),

            _buildParagraph(
              'When a refund request is approved, you may receive either a full order refund for major issues affecting the entire order, a partial refund for specific items that had problems, or in some cases, an option to reorder the affected items at no extra cost.',
            ),

            _buildParagraph(
              'Refund approval is based on several conditions: clear photographic evidence must be provided to support your claim, the claim must be reasonable and valid, it should typically be a first-time issue with the particular merchant, and for full refunds, the order value should be at least ₹200. Orders below this threshold may only qualify for partial refunds or credits.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Reasons for Refund Rejection'),

            _buildParagraph(
              'Refund requests may be rejected for various reasons. Common rejection reasons include insufficient or no photographic evidence to support the claim, claims made beyond the 24-hour time limit after delivery, situations where the customer is at fault such as ordering the wrong item by mistake, multiple refund requests from the same customer indicating potential abuse of the refund system, food allergy issues when allergen information was clearly mentioned in the item description, and cases where a reasonable amount of time has passed suggesting the food was consumed.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Refund Methods and Processing Time'),

            _buildParagraph(
              'Refunds are processed back to your original payment method. The processing time varies depending on the payment method used:',
            ),

            _buildParagraph(
              'For Credit or Debit Card payments, the refund is credited back to your card within 5 to 10 business days. UPI payments are reversed to your UPI account within 1 to 2 hours. Wallet payments receive instant credit back to the wallet. Net Banking transactions are refunded to your bank account within 3 to 7 business days. Please note that these are estimated timeframes and actual processing times may vary depending on your bank or payment provider.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Partial Refunds'),

            _buildParagraph(
              'When only some items in your order have issues, a partial refund may be issued. The refund amount is calculated based on the price of the affected items only, not the entire order total.',
            ),

            _buildParagraph(
              'For example, if your total order was ₹500 and only one item worth ₹150 had an issue, you would receive a refund of ₹150. Delivery charges, packing charges, and other fees are not included in partial refunds unless the entire order is affected.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Non-Refundable Situations'),

            _buildParagraph(
              'Certain charges and situations are not eligible for refunds. These include delivery fees if the delivery was successfully completed, packing charges, items that the customer has partially eaten or consumed, special instructions that were changed after order confirmation, self-pickup orders where the customer is responsible for collection, and offers or discounts that have already been redeemed at the time of order.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Refund Abuse Prevention'),

            _buildParagraph(
              'To maintain fairness and prevent abuse of the refund system, BandiWala monitors refund patterns across all user accounts. If a customer makes 3 or more refund requests within a single month, their account will be flagged for review. Accounts with suspected fraudulent claims may face temporary suspension. Continued patterns of false or unjustified claims can result in permanent account ban.',
            ),

            _buildParagraph(
              'We encourage customers to use the refund system responsibly and only for genuine issues. Abuse of the system affects all users and makes it harder for legitimate complaints to be processed quickly.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Disputes and Appeals'),

            _buildParagraph(
              'If you disagree with a refund decision made by our team, you have the right to appeal. To initiate an appeal, contact our support team within 24 hours of receiving the refund decision. Provide any additional evidence or clarification that may support your case. Our team will conduct a final review of your appeal and communicate the decision within 48 hours. For major disputes involving significant amounts, escalation to our senior review team is available.',
            ),

            const SizedBox(height: 16),
            _buildHeading('Important Notes and Recommendations'),

            _buildParagraph(
              'Always provide clear photographic evidence when reporting issues. Photos should clearly show the problem with your order, such as missing items, wrong items, or quality issues. This documentation is crucial for faster approval of your refund request.',
            ),

            _buildParagraph(
              'Remember the strict time limit of 2 hours from delivery to report issues. Claims made after this window will not be eligible for refunds. We recommend checking your order immediately upon delivery.',
            ),

            _buildParagraph(
              'You can track the status of your refund request at any time by going to Order History in the app and checking the Refund Status section. This will show you the current stage of your refund processing.',
            ),

            const SizedBox(height: 24),
            _buildHeading('Contact Support'),

            _buildParagraph(
              'If you need assistance with refund requests or have any questions regarding this policy, please contact our customer support team:',
            ),

            _buildParagraph(AppEnv.supportContactBlock),

            _buildParagraph(
              'Our support team is dedicated to helping you resolve any issues with your orders and will guide you through the refund process if needed.',
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
