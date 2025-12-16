import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/features/auth/logic/change_password_controller.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/profile/logic/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitPasswordForm(bool hasPassword) {
    if (_formKey.currentState!.validate()) {
      if (hasPassword) {
        // SCENARIO A: Change existing password
        ref.read(changePasswordControllerProvider.notifier).changePassword(
              currentPassword: _currentPasswordController.text,
              newPassword: _newPasswordController.text,
              confirmPassword: _confirmPasswordController.text,
            );
      } else {
        // SCENARIO B: Create new password (API call to set-password)
        ref.read(changePasswordControllerProvider.notifier).setPassword(
              newPassword: _newPasswordController.text,
              confirmPassword: _confirmPasswordController.text,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileControllerProvider);
    final passwordState = ref.watch(changePasswordControllerProvider);

    ref.listen(changePasswordControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            // Refresh profile so hasPassword updates locally
            ref.invalidate(profileControllerProvider);
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.generalSettingsTile,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      // LAYOUT FIX: Wrapped body in SafeArea
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              profileState.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
                error: (_, __) => Text(l10n.failedToLoadProfile,
                    style: const TextStyle(color: Colors.red)),
                data: (user) {
                  final hasPassword = user.hasPassword;

                  return Column(
                    children: [
                      // --- 1. PROFILE HEADER ---
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFCFB56C),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF151E32),
                            child: user.fullName.isNotEmpty
                                ? Text(
                                    user.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFCFB56C),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 50, color: Color(0xFFCFB56C)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 2. INFO SECTION ---
                      _buildSectionContainer(
                        title: l10n.profileInformation,
                        icon: Icons.info_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReadOnlyRow(l10n.fullName, user.fullName),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            _buildReadOnlyRow(l10n.emailAddress, user.email),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 3. PASSWORD SECTION ---
                      _buildSectionContainer(
                        title: hasPassword
                            ? l10n.changePassword
                            : "Create Password",
                        icon: hasPassword
                            ? Icons.lock_outline
                            : Icons.add_moderator_outlined,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Only show Current Password if user HAS a password
                              if (hasPassword) ...[
                                _buildLabel(l10n.currentPassword),
                                _buildPasswordField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrent,
                                  onToggle: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent),
                                  hint: l10n.enterCurrentPassword,
                                  l10n: l10n,
                                ),
                                const SizedBox(height: 16),
                              ],

                              _buildLabel(l10n.newPassword),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                obscureText: _obscureNew,
                                onToggle: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                                hint: l10n.enterNewPassword,
                                l10n: l10n,
                                validator: (value) =>
                                    value!.length < 6 ? l10n.minSixChars : null,
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(l10n.confirmNewPassword),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                hint: l10n.confirmNewPasswordHint,
                                l10n: l10n,
                                validator: (value) =>
                                    value != _newPasswordController.text
                                        ? l10n.passwordsDoNotMatch
                                        : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: passwordState.isLoading
                                      ? null
                                      : () => _submitPasswordForm(hasPassword),
                                  icon: passwordState.isLoading
                                      ? const SizedBox.shrink()
                                      : Icon(
                                          hasPassword
                                              ? Icons.save_as
                                              : Icons.check_circle_outline,
                                          color: Colors.black),
                                  label: passwordState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2))
                                      : Text(hasPassword
                                          ? l10n.updatePassword
                                          : "Create Password"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFCFB56C),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildSectionContainer(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFCFB56C), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String hint,
    required AppLocalizations l10n,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (val) => val!.isEmpty ? l10n.required : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0B101D),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCFB56C))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
