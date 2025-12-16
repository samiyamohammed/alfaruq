import 'dart:async';
import 'dart:math' as math;
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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late ScrollController _scrollController1;
  late ScrollController _scrollController2;
  late ScrollController _scrollController3;
  Timer? _scrollTimer;

  // Logo Animation (Gentle Breathing)
  late AnimationController _logoAnimController;
  late Animation<double> _scaleAnimation;

  // Track if popup is open
  bool _isPopupOpen = false;

  // --- Assets ---
  // Ensure these exist in your assets folder
  final List<String> _posterImages = [
    'assets/images/poster1.png',
    'assets/images/poster2.png',
    'assets/images/poster3.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController1 = ScrollController();
    _scrollController2 = ScrollController();
    _scrollController3 = ScrollController();

    // Setup Animation
    _logoAnimController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeInOutSine),
    );

    // Auto-Scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _safeScroll(_scrollController1, 0.5);
      _safeScroll(_scrollController2, 0.8);
      _safeScroll(_scrollController3, 0.5);
    });
  }

  void _safeScroll(ScrollController controller, double speed) {
    if (!controller.hasClients) return;
    try {
      double maxScroll = controller.position.maxScrollExtent;
      double currentScroll = controller.offset;
      if (currentScroll >= maxScroll) {
        controller.jumpTo(0);
      } else {
        controller.jumpTo(currentScroll + speed);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController1.dispose();
    _scrollController2.dispose();
    _scrollController3.dispose();
    _logoAnimController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _handleGoogleSignIn() {
    ref.read(loginControllerProvider.notifier).signInWithGoogle();
  }

  void _handleGuestLogin() {
    // Triggers the guest token fetch and storage
    ref.read(loginControllerProvider.notifier).loginAsGuest();
  }

  void _showEmailLoginSheet() {
    // Reset provider to clear old errors
    ref.invalidate(loginControllerProvider);
    setState(() => _isPopupOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EmailLoginPopup(),
    ).whenComplete(() {
      if (mounted) setState(() => _isPopupOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    // Global Error Listener
    ref.listen(loginControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          if (!_isPopupOpen) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString(),
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.red[900],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        data: (_) {
          // Success Navigation for any login method (Google, Email, Guest)
          if (previous is AsyncLoading) {
            if (_isPopupOpen && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Grid (Dimmed)
          Opacity(
            opacity: 0.4,
            child: Row(
              children: [
                Expanded(child: _buildInfiniteColumn(_scrollController1)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfiniteColumn(_scrollController2)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfiniteColumn(_scrollController3)),
              ],
            ),
          ),

          // 2. Heavy Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.95),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),

                  // --- 3D Logo ---
                  Center(
                    child: AnimatedBuilder(
                      animation: _logoAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 110,
                        color: const Color(0xFFFDC34E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Al-Faruk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFDC34E),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Islamic Content Streaming',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // --- Email Button ---
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          loginState.isLoading ? null : _showEmailLoginSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDC34E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      child: const Text('Continue with Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Google Button ---
                  Consumer(builder: (context, ref, _) {
                    return SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed:
                            loginState.isLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black54,
                          side:
                              const BorderSide(color: Colors.white24, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/google.png',
                                height: 22,
                                errorBuilder: (c, o, s) => const Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.white)),
                            const SizedBox(width: 12),
                            const Text('Continue with Google',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // --- Footer (Skip & Sign Up) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Centered Skip (Acts as Guest Login)
                      GestureDetector(
                        onTap: loginState.isLoading ? null : _handleGuestLogin,
                        child: loginState.isLoading && !_isPopupOpen
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Skip',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                      ),

                      const Spacer(),

                      // Right-aligned Sign Up
                      const Text("No account? ",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const RegistrationScreen())),
                        child: const Text('Sign Up',
                            style: TextStyle(
                                color: Color(0xFFFDC34E),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "By continuing, you agree to our Terms of Service",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfiniteColumn(ScrollController controller) {
    return ListView.builder(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1000,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                _posterImages[index % _posterImages.length],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Email Login Popup (Unchanged logic, just keeping it here for completeness) ---
class _EmailLoginPopup extends ConsumerStatefulWidget {
  const _EmailLoginPopup();

  @override
  ConsumerState<_EmailLoginPopup> createState() => _EmailLoginPopupState();
}

class _EmailLoginPopupState extends ConsumerState<_EmailLoginPopup> {
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
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final hasError = loginState.hasError;
    final errorMessage = hasError ? loginState.error.toString() : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Welcome Back',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text('Enter your credentials to access your account.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              const SizedBox(height: 24),

              // --- ERROR BOX ---
              if (hasError)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1515),
                    border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFE53935), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMessage
                                  ?.replaceAll(RegExp(r'\[.*?\]'), '')
                                  .trim() ??
                              'Login failed',
                          style: const TextStyle(
                              color: Color(0xFFFF8A80), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Fields
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Email', Icons.mail_outline),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration:
                    _inputDecor('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[500]),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const ForgotPasswordScreen()));
                  },
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: Color(0xFFFDC34E))),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loginState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDC34E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loginState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black))
                      : const Text('Log In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF252525),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFDC34E), width: 1)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade900)),
    );
  }
}
