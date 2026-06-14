import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class WelcomeTourScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;

  const WelcomeTourScreen({
    super.key,
    this.onThemeChanged,
    this.onLocaleChanged,
  });

  @override
  State<WelcomeTourScreen> createState() => _WelcomeTourScreenState();
}

class _WelcomeTourScreenState extends State<WelcomeTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 5;

  void _onNext() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _startExploring();
    }
  }

  void _startExploring() {
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bool isLastPage = _currentPage == _pageCount - 1;

    // Build slide data here so we can use l10n
    final slides = [
      _TourSlide(
        icon: Icons.home_outlined,
        title: l.welcomeTourTitle1,
        body: l.welcomeTourBody1,
      ),
      _TourSlide(
        icon: Icons.local_florist_outlined,
        title: l.welcomeTourTitle2,
        body: l.welcomeTourBody2,
      ),
      _TourSlide(
        icon: Icons.chat_bubble_outline,
        title: l.welcomeTourTitle3,
        body: l.welcomeTourBody3,
      ),
      _TourSlide(
        icon: Icons.camera_alt_outlined,
        title: l.welcomeTourTitle4,
        body: l.welcomeTourBody4,
      ),
      _TourSlide(
        icon: Icons.people_outline,
        title: l.welcomeTourTitle5,
        body: l.welcomeTourBody5,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return _buildSlide(slides[index]);
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.forest700
                              : AppColors.bone300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Start Exploring button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        isLastPage ? l.startExploring : l.tourNext,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_TourSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 80,
            color: AppColors.forest700,
          ),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.bone900,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.bone500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Immutable data class for each tour slide.
class _TourSlide {
  final IconData icon;
  final String title;
  final String body;

  const _TourSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
}
