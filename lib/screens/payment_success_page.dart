// ✅ COMPLETE PaymentSuccessPage.dart - WHITE BG + RANDOM QUOTES
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

const kBandiwalaYellow = Color(0xFFFFC107);
const kWhite = Color(0xFFFFFFFF);

class PaymentSuccessPage extends StatefulWidget {
  final String paymentId;
  final double amount;
  final String orderId;

  const PaymentSuccessPage({
    super.key,
    required this.paymentId,
    required this.amount,
    required this.orderId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _navigationTimer;
  int _countdownSeconds = 4;

  // ✅ 10 RANDOM QUOTES
  final List<String> _quotes = [
    "Food is our common ground, a universal experience. - James Beard",
    "Good food is the foundation of genuine happiness. - Auguste Escoffier",
    "People who love to eat are always the best people. - Julia Child",
    "One cannot think well, love well, sleep well, if not well eaten. - Virginia Woolf",
    "Cooking is like love. It should be entered into with abandon. - Michael Pollan",
    "Food is symbolic of love when words are inadequate. - Alan D. Wolfelt",
    "The joy of tasting a fresh, ripe peach in summer is pure bliss!",
    "Every meal is a chance to nourish body and soul.",
    "Great food brings people together, one bite at a time.",
    "Savor the moment, enjoy the flavor, cherish the memory."
  ];

  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // ✅ Pick random quote
    final random = Random();
    _randomQuote = _quotes[random.nextInt(_quotes.length)];

    _animationController.forward();

    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kWhite, // ✅ WHITE BACKGROUND
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),

                // ✅ SUCCESS ANIMATION - SMALLER IMAGE
                Column(
                  children: [
                    // Small animated logo
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.3, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        width: 100,  // ✅ SMALLER
                        height: 100,
                        decoration: BoxDecoration(
                          color: kWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/splash.png',
                          fit: BoxFit.contain,
                          width: 70,   // ✅ SMALLER
                          height: 70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success checkmark
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.4, 0.8),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBandiwalaYellow.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: kBandiwalaYellow,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Success text
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.5, 1.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Payment Successful!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your order is on the way 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ✅ RANDOM QUOTE (NO BILL DETAILS)
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kBandiwalaYellow.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBandiwalaYellow.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: kBandiwalaYellow,
                          size: 28,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"$_randomQuote"',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '- Food Wisdom',
                          style: TextStyle(
                            fontSize: 13,
                            color: kBandiwalaYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // COUNTDOWN TIMER
                Column(
                  children: [
                    Text(
                      'Redirecting to home in $_countdownSeconds',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _countdownSeconds / 4.0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(kBandiwalaYellow),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kBandiwalaYellow,
                          side: BorderSide(color: kBandiwalaYellow, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Go Home Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
