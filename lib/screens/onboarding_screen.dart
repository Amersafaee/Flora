import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../widgets/shared/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;

  const OnboardingScreen({super.key, this.onThemeChanged});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SignupScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: [
                      _buildPage(
                        icon: Icons.eco,
                        iconSize: 100,
                        iconColor: AppColors.forest700,
                        heading: l.welcomeToDigitalConservatory,
                        subtitle: l.onboardingWelcomeSubtitle,
                        isDark: isDark,
                      ),
                      _buildPageWithStackedIcon(
                        baseIcon: Icons.calendar_today,
                        overlayIcon: Icons.water_drop,
                        heading: l.neverMissACareDay,
                        subtitle: l.onboardingCareSubtitle,
                        isDark: isDark,
                      ),
                      _buildPage(
                        icon: Icons.camera_alt,
                        iconSize: 80,
                        iconColor: AppColors.forest700,
                        heading: l.identifyAnyPlantInstantly,
                        subtitle: l.onboardingIdentifySubtitle,
                        isDark: isDark,
                      ),
                      _buildPage(
                        icon: Icons.people,
                        iconSize: 80,
                        iconColor: AppColors.forest700,
                        heading: l.joinTheCommunity,
                        subtitle: l.onboardingCommunitySubtitle,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: isActive ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.forest700
                                  : AppColors.bone300,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32.0),
                      PrimaryButton(
                        label: _currentPage == 3
                            ? l.letsGrowSomething
                                .replaceAll('🌱', '')
                                .replaceAll('🌿', '')
                                .trim()
                            : l.nextLabel,
                        onPressed:
                            _currentPage == 3 ? _completeOnboarding : _nextPage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentPage < 3)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l.skip,
                    style: const TextStyle(
                      color: AppColors.bone500,
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required double iconSize,
    required Color iconColor,
    required String heading,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(height: 48.0),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28.0,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.0,
              color: AppColors.bone500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageWithStackedIcon({
    required IconData baseIcon,
    required IconData overlayIcon,
    required String heading,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(baseIcon, size: 80, color: AppColors.forest700),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.bone50,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.water_drop,
                        size: 40, color: AppColors.forest300),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48.0),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28.0,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.0,
              color: AppColors.bone500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
