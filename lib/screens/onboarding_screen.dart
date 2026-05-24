import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';

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
        builder: (context) => SignupScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const Color accentColor = AppColors.forest900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildPage(
                        icon: Icons.eco,
                        iconSize: 100,
                        iconColor: accentColor,
                        heading: l.welcomeToDigitalConservatory,
                        subtitle: l.onboardingWelcomeSubtitle,
                      ),
                      _buildPageWithStackedIcon(
                        baseIcon: Icons.calendar_today,
                        overlayIcon: Icons.water_drop,
                        heading: l.neverMissACareDay,
                        subtitle: l.onboardingCareSubtitle,
                        accentColor: accentColor,
                      ),
                      _buildPage(
                        icon: Icons.camera_alt,
                        iconSize: 80,
                        iconColor: accentColor,
                        heading: l.identifyAnyPlantInstantly,
                        subtitle: l.onboardingIdentifySubtitle,
                      ),
                      _buildPage(
                        icon: Icons.people,
                        iconSize: 80,
                        iconColor: accentColor,
                        heading: l.joinTheCommunity,
                        subtitle: l.onboardingCommunitySubtitle,
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
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: isActive ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.forest700 : AppColors.bone300,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32.0),
                      SizedBox(
                        width: double.infinity,
                        height: 54.0,
                        child: ElevatedButton(
                          onPressed: _currentPage == 3 ? _completeOnboarding : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.0),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == 3
                                ? l.letsGrowSomething.replaceAll('🌱', '').replaceAll('🌿', '').trim()
                                : l.nextLabel,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(height: 48.0),
          Text(heading, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'serif', fontSize: 28.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16.0),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: AppColors.bone500, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPageWithStackedIcon({
    required IconData baseIcon,
    required IconData overlayIcon,
    required String heading,
    required String subtitle,
    required Color accentColor,
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
                Icon(baseIcon, size: 80, color: accentColor),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: Icon(overlayIcon, size: 40, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48.0),
          Text(heading, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'serif', fontSize: 28.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16.0),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: AppColors.bone500, height: 1.5)),
        ],
      ),
    );
  }
}
