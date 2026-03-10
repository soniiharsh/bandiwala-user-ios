import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../services/notification_service.dart';
import 'home_page.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> with CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color bandiwalaYellow = Color(0xFFFFC107);
  bool _isLoading = false;
  int _resendTimer = 26;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _listenForOTP(); // ✅ System will request permission automatically
  }

  // ✅ Listen for incoming SMS OTP (system handles permission)
  Future<void> _listenForOTP() async {
    try {
      // This will trigger system permission dialog automatically
      listenForCode();

      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('📱 App Signature: $signature');
    } catch (e) {
      debugPrint('❌ SMS AutoFill Error: $e');
    }
  }

  // ✅ Called when OTP is auto-detected
  @override
  void codeUpdated() {
    if (mounted && code != null && code!.length == 6) {
      setState(() {
        _otpController.text = code!;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('OTP detected automatically'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _verifyOTP();
        }
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    _resendTimer = 26;
    _canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
        timer.cancel();
      }
    });
  }

  Future<void> _createCustomerIfNeeded(String phone) async {
    try {
      final customers = FirebaseFirestore.instance.collection('customers');
      // Normalize: always remove +91 for document ID
      final phoneWithoutCode = phone.replaceAll('+91', '');
      final docRef = customers.doc(phoneWithoutCode);

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        await docRef.set({
          'phone': phone, // Store full number with +91
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Customer creation failed: $e');
    }
  }

  Future<void> _saveLoginState(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userPhone', phone);
    } catch (e) {
      debugPrint('Save login state failed: $e');
    }
  }

  Future<void> _completeSignIn(String phone) async {
    await _createCustomerIfNeeded(phone);
    await _saveLoginState(phone);
    
    // Update FCM token
    await NotificationService().updateCustomerToken(phone);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage(phoneNumber: phone)),
      (route) => false,
    );
  }

  Future<void> _verifyOTP() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      await _completeSignIn(widget.phoneNumber);
    } on FirebaseAuthException catch (e) {
      // ✅ Handle case where native auto-verification (verificationCompleted)
      // already signed the user in, making this verification attempt redundant.
      if (e.code == 'session-expired' && _auth.currentUser != null) {
        await _completeSignIn(widget.phoneNumber);
        return;
      }

      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new one.';
          break;
        case 'invalid-phone-number':
          errorMessage = 'Invalid phone number. Please try again.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message ?? 'Unknown error'}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _canResend = false;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _completeSignIn(widget.phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Resend failed: ${e.message ?? 'Unknown error'}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        codeSent: (String newVerificationId, int? resendToken) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New OTP sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _startResendTimer();
            _listenForOTP();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resend failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Verify OTP',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We've sent a 6-digit code to\n${widget.phoneNumber}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 32),

                        // ✅ Pin Field with visible cursor
                        Form(
                          key: _formKey,
                          child: PinFieldAutoFill(
                            controller: _otpController,
                            codeLength: 6,
                            autoFocus: true,
                            cursor: Cursor(
                              width: 2,
                              height: 24,
                              color: bandiwalaYellow,
                              radius: const Radius.circular(1),
                              enabled: true,
                            ),
                            decoration: UnderlineDecoration(
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              colorBuilder: FixedColorBuilder(
                                Colors.grey.shade300,
                              ),
                              bgColorBuilder: FixedColorBuilder(
                                Colors.transparent,
                              ),
                              lineHeight: 2,
                              lineStrokeCap: StrokeCap.round,
                            ),
                            currentCode: _otpController.text,
                            onCodeSubmitted: (code) {
                              _verifyOTP();
                            },
                            onCodeChanged: (code) {
                              if (code?.length == 6) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (mounted) {
                                      _verifyOTP();
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bandiwalaYellow,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black87,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _canResend
                                    ? "Didn't receive OTP?"
                                    : 'Resend code in $_resendTimer s',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: (_canResend && !_isLoading)
                                    ? _resendOTP
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: (_canResend && !_isLoading)
                                          ? bandiwalaYellow
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
