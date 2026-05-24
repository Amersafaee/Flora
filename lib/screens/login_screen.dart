import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;

  const LoginScreen({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _mapFirebaseError(String? code, String fallback) {
    final l = AppLocalizations.of(context);
    switch (code) {
      case 'user-not-found':
        return l.noAccountFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l.incorrectPassword;
      case 'network-request-failed':
        return l.noInternetTryAgain;
      case 'too-many-requests':
        return l.tooManyAttempts;
      default:
        return fallback;
    }
  }

  void _login() async {
    final l = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService
          .signInWithEmailAndPassword(email, password)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => '__timeout__',
      );

      if (!mounted) return;

      if (result != 'Success') {
        final message = result == '__timeout__'
            ? l.connectionSlow
            : _mapFirebaseError(result, result ?? l.signInFailed);
        _showError(message);
      }

      if (result == 'Success' && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainTabScreen(
            onThemeChanged: widget.onThemeChanged ?? (_) {},
            onLocaleChanged: widget.onLocaleChanged ?? (_) {},
          )),
          (route) => false,
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_mapFirebaseError(e.code, e.message ?? AppLocalizations.of(context).signInFailed));
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).unexpectedError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.terracotta900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result == 'Success') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainTabScreen(
            onThemeChanged: widget.onThemeChanged ?? (_) {},
            onLocaleChanged: widget.onLocaleChanged ?? (_) {},
          )),
          (route) => false,
        );
      } else if (result != 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.googleSignInFailed), backgroundColor: colorScheme.error),
        );
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo (FIX 5)
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
              const SizedBox(height: 24),

              // Title and Subtitle
              Text(
                l.digitalConservatory,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).welcomeBackToYourSanctuary,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.bone500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),

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
                  fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
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
                onSubmitted: (_) => _login(),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.bone500),
                    onPressed: _isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                ),
              ),
              const SizedBox(height: 40),

              // Sign In Button (FIX 5)
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest700,
                    disabledBackgroundColor: AppColors.forest700.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(l.signIn, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

              // Google Button (FIX 5)
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
                  Text(l.newHereQ, style: const TextStyle(color: AppColors.bone500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(
                                  onThemeChanged: widget.onThemeChanged,
                                  onLocaleChanged: widget.onLocaleChanged,
                                ),
                              ),
                            );
                          },
                    child: Text(
                      l.createAnAccount,
                      style: const TextStyle(color: AppColors.terracotta900, fontWeight: FontWeight.bold),
                    ),
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
