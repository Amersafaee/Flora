import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A white rounded card with a soft shadow.
/// Wrap any content in this to give it the Flora card look.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          splashColor: AppColors.dew.withValues(alpha: 0.3),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}

