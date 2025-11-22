// lib/src/features/auth/screens/otp_screen.dart
import 'dart:async'; // ADDED: Import for the Timer class

import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:al_faruk_app/src/features/auth/logic/forgot_password_controller.dart'; // ADDED: Import the controller
import 'package:al_faruk_app/src/features/auth/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();

  // --- ADDED: State variables for the timer ---
  Timer? _timer;
  int _countdown = 60;
  bool _isResendButtonActive = false;

  @override
  void initState() {
    super.initState();
    // Start the timer as soon as the screen loads
    startTimer();
  }

  @override
  void dispose() {
    // Clean up the timer and controller to prevent memory leaks
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // --- ADDED: Method to start the cooldown timer ---
  void startTimer() {
    setState(() {
      _isResendButtonActive = false;
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isResendButtonActive = true;
        });
      }
    });
  }

  // --- ADDED: Method to handle the resend logic ---
  void _resendOtp() {
    // Start the timer again
    startTimer();
    // Re-trigger the forgot password logic using the controller
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetOtp(email: widget.email);
  }

  void _verifyAndProceed() {
    if (_otpController.text.length == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: _otpController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 6-digit OTP.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the forgotPasswordController to show a SnackBar on resend success/failure
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null &&
              (previous is AsyncLoading || previous == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
      );
    });

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.hintColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: AppTheme.primaryColor)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                  onPressed: _verifyAndProceed, child: const Text('Verify')),
              const SizedBox(height: 20),

              // --- UPDATED: The resend button is now functional ---
              TextButton(
                // The button is disabled unless _isResendButtonActive is true
                onPressed: _isResendButtonActive ? _resendOtp : null,
                child: Text(
                  // The text changes based on the timer's state
                  _isResendButtonActive
                      ? "Didn't receive code? Resend"
                      : "Resend in $_countdown seconds",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
