// // lib/src/features/auth/screens/login_screen.dart
// import 'package:al_faruk_app/src/features/auth/logic/login_controller.dart';
// import 'package:al_faruk_app/src/features/auth/logic/social_auth_controller.dart';
// import 'package:al_faruk_app/src/features/auth/screens/forgot_password_screen.dart';
// import 'package:al_faruk_app/src/features/auth/screens/registration_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _login() {
//     FocusScope.of(context).unfocus();
//     if (_formKey.currentState!.validate()) {
//       ref.read(loginControllerProvider.notifier).loginUser(
//             email: _emailController.text,
//             password: _passwordController.text,
//           );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     ref.listen(
//         loginControllerProvider,
//         (p, next) =>
//             next.whenOrNull(error: (e, s) => _showError(e.toString())));
//     ref.listen(
//         socialAuthControllerProvider,
//         (p, next) =>
//             next.whenOrNull(error: (e, s) => _showError(e.toString())));

//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 40),
//                 Image.asset('assets/images/logo.png', height: 120),
//                 const SizedBox(height: 40),
//                 Text('Welcome Back',
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context)
//                         .textTheme
//                         .headlineSmall
//                         ?.copyWith(fontWeight: FontWeight.bold)),
//                 Text('Log in to your account',
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyLarge
//                         ?.copyWith(color: Colors.grey[600])),
//                 const SizedBox(height: 40),
//                 TextFormField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: const InputDecoration(labelText: 'Email Address'),
//                   validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
//                       ? 'Please enter a valid email'
//                       : null,
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     suffixIcon: IconButton(
//                       icon: Icon(_obscurePassword
//                           ? Icons.visibility_off
//                           : Icons.visibility),
//                       onPressed: () =>
//                           setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                   ),
//                   validator: (v) => (v == null || v.isEmpty)
//                       ? 'Password cannot be empty'
//                       : null,
//                 ),
//                 const SizedBox(height: 12),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (c) => const ForgotPasswordScreen())),
//                     child: const Text('Forgot Password?'),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Consumer(
//                   builder: (context, ref, child) {
//                     final loginState = ref.watch(loginControllerProvider);
//                     return ElevatedButton(
//                       onPressed: loginState.isLoading ? null : _login,
//                       child: loginState.isLoading
//                           ? const SizedBox(
//                               height: 24,
//                               width: 24,
//                               child: CircularProgressIndicator(strokeWidth: 2))
//                           : const Text('Login'),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 Row(children: [
//                   const Expanded(child: Divider(thickness: 1)),
//                   Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                       child: Text('OR',
//                           style: TextStyle(color: Colors.grey.shade600))),
//                   const Expanded(child: Divider(thickness: 1)),
//                 ]),
//                 const SizedBox(height: 24),
//                 Consumer(
//                   builder: (context, ref, child) {
//                     final socialState = ref.watch(socialAuthControllerProvider);
//                     return socialState.isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               IconButton(
//                                 icon: Image.asset('assets/icons/google.png',
//                                     height: 40),
//                                 iconSize: 40,
//                                 onPressed: () => ref
//                                     .read(socialAuthControllerProvider.notifier)
//                                     .signInWithGoogle(),
//                               ),
//                               const SizedBox(width: 24),
//                               IconButton(
//                                 icon: Image.asset('assets/icons/facebook.png',
//                                     height: 40),
//                                 iconSize: 40,
//                                 onPressed: () {/* TODO */},
//                               ),
//                             ],
//                           );
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Don't have an account?"),
//                     TextButton(
//                         onPressed: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (c) => const RegistrationScreen())),
//                         child: const Text('Sign Up')),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//           content: Text(message),
//           backgroundColor: Theme.of(context).colorScheme.error),
//     );
//   }
// }
// lib/src/features/auth/screens/login_screen.dart
import 'package:al_faruk_app/src/features/auth/logic/login_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/forgot_password_screen.dart';
import 'package:al_faruk_app/src/features/auth/screens/registration_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class LoginScreen extends ConsumerStatefulWidget {
const LoginScreen({super.key});
@override
ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends ConsumerState<LoginScreen> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
bool _obscurePassword = true;
@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}
void _login() {
FocusScope.of(context).unfocus();
if (_formKey.currentState!.validate()) {
ref.read(loginControllerProvider.notifier).loginUser(
email: _emailController.text,
password: _passwordController.text,
);
}
}
@override
Widget build(BuildContext context) {
ref.listen(loginControllerProvider, (previous, next) {
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
Navigator.of(context).pushAndRemoveUntil(
MaterialPageRoute(builder: (context) => const MainScreen()),
(route) => false,
);
}
},
);
});
return Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 40),
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Log in to your account',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ForgotPasswordScreen()));
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, child) {
                final loginState = ref.watch(loginControllerProvider);
                final isLoading = loginState is AsyncLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Login'),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('OR',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Image.asset('assets/icons/google.png', height: 40),
                  iconSize: 40,
                  onPressed: () {},
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon:
                      Image.asset('assets/icons/facebook.png', height: 40),
                  iconSize: 40,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegistrationScreen()));
                  },
                  child: const Text('Sign Up'),
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