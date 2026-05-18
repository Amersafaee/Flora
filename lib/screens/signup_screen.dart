import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import 'login_screen.dart';
import '../main.dart';
import '../theme/app_theme.dart';

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
  File? _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _signup() async {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your full name', style: TextStyle(color: Colors.white)),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          elevation: 4,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpWithEmailAndPassword(email, password);

      if (result != 'Success' && mounted) {
        setState(() => _isLoading = false);
        String friendlyMessage;
        if (result == null) {
          friendlyMessage = 'An unexpected error occurred. Please try again.';
        } else if (result.contains('email-already-in-use') || result.contains('account already exists')) {
          friendlyMessage = 'An account with this email already exists';
        } else if (result.contains('weak-password') || result.contains('too weak')) {
          friendlyMessage = 'Password must be at least 6 characters';
        } else if (result.contains('invalid-email') || result.contains('badly formatted')) {
          friendlyMessage = 'Please enter a valid email address';
        } else {
          friendlyMessage = result;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (result == 'Success' && mounted) {
        // Save fullName and profile data to Firestore
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final userData = <String, dynamic>{
            'fullName': name,
            'displayName': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Upload profile photo if selected — skip entirely if null
          if (_profileImage != null) {
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('users/$uid/profile/profile.jpg');
              await storageRef.putFile(
                _profileImage!,
                SettableMetadata(contentType: 'image/jpeg'),
              );
              final downloadUrl = await storageRef.getDownloadURL();
              userData['profilePhotoUrl'] = downloadUrl;
            } catch (e) {
              debugPrint('Profile photo upload failed during signup: $e');
              // Non-fatal — continue signup without photo
            }
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(userData, SetOptions(merge: true));

          // Also update FirebaseAuth displayName
          if (name.isNotEmpty) {
            await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
          }
        }

        await OnboardingService.initForNewUser();

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Explicit navigation to MainTabScreen as fallback (same pattern as login)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainTabScreen(
              onThemeChanged: widget.onThemeChanged ?? (_) {},
              onLocaleChanged: widget.onLocaleChanged ?? (_) {},
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign up failed: ${e.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final colorScheme = Theme.of(context).colorScheme;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Google sign in failed. Please try again.'), backgroundColor: colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickProfileImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? Icon(Icons.person, color: primaryColor, size: 44)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Add Photo (optional)',
                  style: TextStyle(color: AppColors.bone500, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Subtitle
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start your plant journey today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.bone500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Name Input
              Text(
                'Full Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.forest900, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.forest900, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Input
              Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                onSubmitted: (_) => _signup(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.bone500,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.forest900, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Create Account Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text('or', style: TextStyle(color: AppColors.bone500)),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              OutlinedButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      child: const Center(
                        child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Continue with Google', style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Already have an account? Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: AppColors.bone500),
                  ),
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
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.terracotta900,
                        fontWeight: FontWeight.bold,
                      ),
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
