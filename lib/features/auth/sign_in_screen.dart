import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum _AuthView { landing, signIn, signUp }

class _SignInScreenState extends State<SignInScreen> {
  _AuthView _view = _AuthView.landing;
  bool _loading = false;

  // Sign In fields
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;

  // Sign Up extra fields
  final _nameCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureConfirm   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _clearFields() {
    _emailCtrl.clear();
    _passCtrl.clear();
    _nameCtrl.clear();
    _confirmPassCtrl.clear();
  }

  // ── Sign In ─────────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (pass.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    try {
      debugPrint('[Flora] Signing in...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      ).timeout(const Duration(seconds: 15));
      debugPrint('[Flora] Sign-in success, navigating to /home');
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Flora] Sign-in error: ${e.code} - ${e.message}');
      _showError(_friendlyError(e));
    } catch (e) {
      debugPrint('[Flora] Sign-in error: $e');
      if (e.toString().contains('TimeoutException')) {
        _showError('Connection timed out. Check your internet and make sure Email/Password is enabled in Firebase Console.');
      } else {
        _showError('Something went wrong: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Sign Up ─────────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final pass    = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Create the Firebase Auth account
      debugPrint('[Flora] Step 1: Creating account...');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      ).timeout(const Duration(seconds: 15));
      debugPrint('[Flora] Step 1 DONE — uid: ${cred.user?.uid}');

      // 2. Set display name before navigating so the router knows they have a profile
      if (cred.user != null) {
        await cred.user!.updateDisplayName(name);
        // Force reload to ensure authNotifier picks up the updated user object
        await cred.user!.reload();
      }

      // 3. Navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🌱 Welcome to Flora! Your garden awaits.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.go('/home');
      }

      // 4. Set Firestore in background (fire-and-forget)
      _saveProfileInBackground(FirebaseAuth.instance.currentUser, name, email);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Flora] Sign-up auth error: ${e.code} - ${e.message}');
      _showError(_friendlyError(e));
    } catch (e) {
      debugPrint('[Flora] Sign-up error: $e');
      if (e.toString().contains('TimeoutException')) {
        _showError('Connection timed out. Check your internet and make sure Email/Password is enabled in Firebase Console.');
      } else {
        _showError('Something went wrong: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
        return 'No account found with this email. Try creating one!';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in!';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  // ── Background profile save (fire-and-forget) ─────────────────────────────
  void _saveProfileInBackground(User? user, String name, String email) {
    if (user == null) return;
    Future(() async {
      try {
        debugPrint('[Flora] BG: Setting display name...');
        await user.updateDisplayName(name);
        debugPrint('[Flora] BG: Display name set');
      } catch (e) {
        debugPrint('[Flora] BG: Display name failed: $e');
      }
      try {
        debugPrint('[Flora] BG: Writing Firestore profile...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'displayName': name,
          'email':       email,
          'photoUrl':    '',
          'createdAt':   FieldValue.serverTimestamp(),
          'plantsCount': 0,
        }, SetOptions(merge: true));
        debugPrint('[Flora] BG: Firestore profile written');
      } catch (e) {
        debugPrint('[Flora] BG: Firestore write failed: $e');
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── Logo ────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3314301E),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Heading ─────────────────────────────────────────────────
              Text(
                _view == _AuthView.signUp
                    ? 'Create Account'
                    : 'Welcome to Flora',
                style: TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.forestGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _view == _AuthView.signUp
                    ? 'Join Flora and start your plant journey.'
                    : _view == _AuthView.signIn
                        ? 'Sign in to your plant collection.'
                        : 'Your personal plant companion.',
                style: tt.bodyMedium?.copyWith(color: AppColors.moss),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ── Landing view ────────────────────────────────────────────
              if (_view == _AuthView.landing) ...[
                _ActionButton(
                  label: 'Sign In',
                  icon: Icons.login,
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  onPressed: () => setState(() => _view = _AuthView.signIn),
                ),
                const SizedBox(height: 14),
                _ActionButton(
                  label: 'Create Account',
                  icon: Icons.person_add_outlined,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.forestGreen,
                  borderColor: AppColors.forestGreen,
                  onPressed: () => setState(() => _view = _AuthView.signUp),
                ),
              ],

              // ── Sign In view ────────────────────────────────────────────
              if (_view == _AuthView.signIn) ...[
                _InputField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePass,
                  onToggleObscure: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  label: 'Sign In',
                  icon: Icons.login,
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  loading: _loading,
                  onPressed: _loading ? null : _signIn,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _view = _AuthView.signUp;
                      _clearFields();
                    }),
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.moss),
                    ),
                  ),
                ),
                _BackButton(onPressed: () => setState(() {
                  _view = _AuthView.landing;
                  _clearFields();
                })),
              ],

              // ── Sign Up view ────────────────────────────────────────────
              if (_view == _AuthView.signUp) ...[
                _InputField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePass,
                  onToggleObscure: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _confirmPassCtrl,
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  label: 'Create Account',
                  icon: Icons.person_add_outlined,
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  loading: _loading,
                  onPressed: _loading ? null : _signUp,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _view = _AuthView.signIn;
                      _clearFields();
                    }),
                    child: Text(
                      'Already have an account? Sign In',
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.moss),
                    ),
                  ),
                ),
                _BackButton(onPressed: () => setState(() {
                  _view = _AuthView.landing;
                  _clearFields();
                })),
              ],

              const SizedBox(height: 32),
              Text(
                'By continuing you agree to our Terms & Privacy Policy.',
                style: tt.bodySmall?.copyWith(color: AppColors.moss),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable input field ──────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Reusable action button ────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool loading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderPill,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: foregroundColor))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    )),
                ],
              ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text('← Back', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.moss)),
      ),
    );
  }
}

