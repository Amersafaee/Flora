import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

class OnboardingOverlayScreen extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tips;
  final String featureKey;
  final VoidCallback? onDismiss;

  const OnboardingOverlayScreen({
    super.key,
    required this.title,
    required this.description,
    required this.tips,
    required this.featureKey,
    this.onDismiss,
  });

  void _dismiss(BuildContext context) {
    OnboardingService.markShown(featureKey);
    Navigator.pop(context);
    onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) OnboardingService.markShown(featureKey);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => _dismiss(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xCC000000),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 32, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: Icon(Icons.eco, color: AppColors.forest600, size: 48)),
                      const SizedBox(height: 20),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, color: AppColors.bone500, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      ...tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.forest600, size: 16),
                              const SizedBox(width: 10),
                              Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4))),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _dismiss(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest900,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            l.gotItLetsGo,
                            style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      Center(
                        child: TextButton(
                          onPressed: () => _dismiss(context),
                          child: Text(l.skip, style: const TextStyle(color: AppColors.bone500, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
