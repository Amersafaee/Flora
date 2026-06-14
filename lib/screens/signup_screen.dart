import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import 'login_screen.dart';
import 'welcome_tour_screen.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/toast_utils.dart';

class SignupScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;

  const SignupScreen({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    final l = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.trim().isEmpty) {
      showToast(context, l.pleaseEnterFullName, isError: true);
      return;
    }

    if (email.isEmpty || password.isEmpty) return;

    if (password.length < 6) {
      showToast(context, l.passwordTooWeak, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpWithEmailAndPassword(email, password);

      if (result != 'Success' && mounted) {
        setState(() => _isLoading = false);
        String friendlyMessage;
        if (result == null) {
          friendlyMessage = l.unexpectedError;
        } else if (result.contains('email-already-in-use') || result.contains('account already exists')) {
          friendlyMessage = l.emailAlreadyInUse;
        } else if (result.contains('weak-password') || result.contains('too weak')) {
          friendlyMessage = l.passwordTooWeak;
        } else if (result.contains('invalid-email') || result.contains('badly formatted')) {
          friendlyMessage = l.invalidEmail;
        } else {
          friendlyMessage = result;
        }
        showToast(context, friendlyMessage, isError: true);
        return;
      }

      if (result == 'Success' && mounted) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final userData = <String, dynamic>{
            'fullName': name,
            'displayName': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          };


          await FirebaseFirestore.instance.collection('users').doc(uid).set(userData, SetOptions(merge: true));
          if (name.isNotEmpty) {
            await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
          }
        }

        await OnboardingService.initForNewUser();

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => WelcomeTourScreen(
              onThemeChanged: widget.onThemeChanged,
              onLocaleChanged: widget.onLocaleChanged,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (mounted) {
        final l2 = AppLocalizations.of(context);
        setState(() => _isLoading = false);
        showToast(context, '${l2.signUpFailedPrefix}${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final l = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result == 'Success') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data()?['isNewUser'] == true) {
            await OnboardingService.initForNewUser();
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isNewUser': false});
          }
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainTabScreen(
            onThemeChanged: widget.onThemeChanged ?? (_) {},
            onLocaleChanged: widget.onLocaleChanged ?? (_) {},
          )),
          (route) => false,
        );
      } else if (result != 'cancelled') {
        showToast(context, l.googleSignInFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botanical Logo (FIX 1)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.eco,
                      color: AppColors.forest700,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(l.createAccount, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).yourPlantsAssistantSanctuary,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.bone500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              Text(l.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // Email
              Text(l.email, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // Password
              Text(l.password, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                onSubmitted: (_) => _signup(),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.bone500),
                    onPressed: _isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                ),
              ),
              const SizedBox(height: 40),

              // Create Account Button (FIX 3)
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest700,
                    disabledBackgroundColor: AppColors.forest700.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l.createAccount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.or, style: const TextStyle(color: AppColors.bone500)),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // Google Button (FIX 3)
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.bone200, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.bone200),
                        ),
                        child: const Center(child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l.continueWithGoogle,
                        style: const TextStyle(
                          color: AppColors.bone700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.alreadyHaveAccountQ, style: const TextStyle(color: AppColors.bone500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  onThemeChanged: widget.onThemeChanged,
                                  onLocaleChanged: widget.onLocaleChanged,
                                ),
                              ),
                            );
                          },
                    child: Text(l.signIn, style: const TextStyle(color: AppColors.forest700, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
