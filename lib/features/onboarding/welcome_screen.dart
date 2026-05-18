import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─── Splash / Welcome screen ───────────────────────────────────────────────────
// Shown for 600 ms, then routes to the correct next screen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();

    // Navigate after 600 ms logo display + brief pause
    Future.delayed(const Duration(milliseconds: 1400), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;

    if (user != null) {
      // Already signed in → go straight to home tabs
      if (mounted) context.go('/home');
      return;
    }

    // Check if the user has seen the intro carousel before
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    if (!mounted) return;
    if (seenIntro) {
      context.go('/sign-in');
    } else {
      context.go('/intro');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone50, // AppColors.cream
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Leaf icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.forest900,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3314301E),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 52)),
                  ),
                ),
                const SizedBox(height: 20),
                // App name in Noto Serif
                Text(
                  'Flora',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: AppColors.forest900.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personal plant companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.forest500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

