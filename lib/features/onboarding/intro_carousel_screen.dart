import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// ─── Intro carousel ────────────────────────────────────────────────────────────
// Shown only once. Uses SharedPreferences to remember it was seen.
class IntroCarouselScreen extends StatefulWidget {
  const IntroCarouselScreen({super.key});

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
    if (mounted) context.go('/sign-in');
  }

  void _next(int slidesLength) {
    if (_page < slidesLength - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Slides built lazily so titles/subtitles are localized at runtime
    final slides = [
      _Slide(
        emoji: '🌿',
        title: l.identifyAnyPlant,
        subtitle: l.cameraFloraNames,
        bgColor: const Color(0xFFF5F0E8),
        darkBgColor: AppColors.darkCanvas,
        accentColor: AppColors.forest900,
        darkAccentColor: AppColors.darkForestPrimary,
      ),
      _Slide(
        emoji: '📅',
        title: l.neverMissAWatering,
        subtitle: l.floraRemindsWhenToCare,
        bgColor: const Color(0xFFE8F4E8),
        darkBgColor: AppColors.darkCanvas,
        accentColor: AppColors.forest900,
        darkAccentColor: AppColors.darkForestPrimary,
      ),
      _Slide(
        emoji: '👥',
        title: l.swapWithPlantLovers,
        subtitle: l.tradeCuttingsLocally,
        bgColor: const Color(0xFFF0EDE8),
        darkBgColor: AppColors.darkCanvas,
        accentColor: const Color(0xFF5C4033),
        darkAccentColor: AppColors.darkTerracotta,
      ),
    ];

    final slide = slides[_page];
    final isLast = _page == slides.length - 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = isDark ? slide.darkBgColor : slide.bgColor;
    final effectiveAccent = isDark ? slide.darkAccentColor : slide.accentColor;

    return Scaffold(
      backgroundColor: effectiveBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: slides.length,
                    itemBuilder: (_, i) => _SlideView(slide: slides[i]),
                  ),
                ),

                // Dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? effectiveAccent : effectiveAccent.withAlpha(60),
                          borderRadius: AppRadius.borderPill,
                        ),
                      );
                    }),
                  ),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: isLast
                      ? _PrimaryButton(label: l.getStarted, color: effectiveAccent, onPressed: _finish)
                      : _PrimaryButton(label: l.nextLabel, color: effectiveAccent, onPressed: () => _next(slides.length)),
                ),
              ],
            ),

            // Skip button (slides 1 & 2 only)
            if (!isLast)
              Positioned(
                top: 8,
                right: 16,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l.skip,
                    style: TextStyle(color: effectiveAccent.withAlpha(180), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Individual slide ───────────────────────────────────────────────────────────
class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color darkBgColor;
  final Color accentColor;
  final Color darkAccentColor;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.darkBgColor,
    required this.accentColor,
    required this.darkAccentColor,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? slide.darkAccentColor : slide.accentColor;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: accent.withAlpha(40), width: 1.5),
            ),
            child: Center(child: Text(slide.emoji, style: const TextStyle(fontSize: 72))),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: TextStyle(fontFamily: 'NotoSerif', fontSize: 28, fontWeight: FontWeight.w700, color: accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            style: tt.bodyLarge?.copyWith(color: accent.withAlpha(180), height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Reusable primary button ────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        child: Text(label),
      ),
    );
  }
}
