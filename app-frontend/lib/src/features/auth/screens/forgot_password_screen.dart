// lib/src/features/auth/screens/forgot_password_screen.dart
import 'package:al_faruk_app/src/features/auth/logic/forgot_password_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(forgotPasswordControllerProvider.notifier)
          .sendResetOtp(email: _emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            // --- THE BUG FIX IS HERE ---
            // We now pass the email from the text controller to the OTPScreen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OTPScreen(email: _emailController.text),
              ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                  'Enter the email associated with your account and we\'ll send an email with instructions to reset your password.'),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(forgotPasswordControllerProvider);
                  return ElevatedButton(
                    onPressed: state.isLoading ? null : _sendOtp,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send OTP'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
