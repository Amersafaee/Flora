import 'package:flutter/material.dart';
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
        builder: (context) => SignupScreen(
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = AppColors.forest900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    icon: Icons.eco,
                    iconSize: 100,
                    iconColor: accentColor,
                    heading: 'Welcome to Digital Conservatory',
                    subtitle: 'Your personal AI plant sanctuary. Meet Flora — she knows your plants and keeps them thriving.',
                  ),
                  _buildPageWithStackedIcon(
                    baseIcon: Icons.calendar_today,
                    overlayIcon: Icons.water_drop,
                    heading: 'Never Miss a Care Day',
                    subtitle: 'Flora builds a smart care calendar for every plant you own and reminds you exactly when to water, fertilize, and check in.',
                    accentColor: accentColor,
                  ),
                  _buildPage(
                    icon: Icons.camera_alt,
                    iconSize: 80,
                    iconColor: accentColor,
                    heading: 'Identify Any Plant Instantly',
                    subtitle: 'Point your camera at any plant for instant AI identification, health diagnosis, and a personalized care plan from Flora.',
                  ),
                  _buildPage(
                    icon: Icons.people,
                    iconSize: 80,
                    iconColor: accentColor,
                    heading: 'Join the Community',
                    subtitle: 'Share your journey, swap cuttings with local plant lovers, and get expert advice from thousands of plant parents.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: _currentPage == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? accentColor : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32.0),
                  if (_currentPage == 3)
                    // Last page: single centered CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56.0,
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Let\'s grow something 🌱',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    // Pages 1-3: Skip on left, Next on right
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56.0,
                            child: OutlinedButton(
                              onPressed: _completeOnboarding,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accentColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56.0,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
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
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(overlayIcon, size: 40, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48.0),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
