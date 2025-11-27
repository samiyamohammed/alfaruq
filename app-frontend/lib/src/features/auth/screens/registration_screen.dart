// lib/src/features/auth/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/registration_controller.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});
  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- UPDATED: Split controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You must agree to the Terms of Service & Privacy Policy.')),
        );
        return;
      }
      ref.read(registrationControllerProvider.notifier).registerUser(
            firstName: _firstNameController.text, // Pass separately
            lastName: _lastNameController.text, // Pass separately
            email: _emailController.text,
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registrationControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error.toString()),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        },
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Registration Successful!'),
                  backgroundColor: Colors.green),
            );
            Future.delayed(
                const Duration(seconds: 1), () => Navigator.pop(context));
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- UPDATED: First Name Field ---
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 20),

              // --- UPDATED: Last Name Field ---
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (v) => v!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) =>
                        setState(() => _agreeToTerms = value!)),
                const Expanded(
                    child: Text(
                        'I agree to the Terms of Service & Privacy Policy.'))
              ]),
              const SizedBox(height: 30),
              Consumer(
                builder: (context, ref, child) {
                  final registrationState =
                      ref.watch(registrationControllerProvider);
                  return ElevatedButton(
                    onPressed:
                        registrationState.isLoading ? null : _onSignUpPressed,
                    child: registrationState.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign Up'),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Log In'))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
