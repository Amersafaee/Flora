import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A standard Verdoro card with rounded corners, a soft shadow, and an
/// optional tap callback.
///
/// Spec: borderRadius 16, bone50/darkSurface background,
/// BoxShadow(Color(0x0A224A1E), blurRadius 8, offset Offset(0, 2)).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
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
        color: isDark ? AppColors.darkCardSurface : AppColors.bone50,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppColors.darkCardBorder, width: 1)
            : null,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A224A1E),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0x4CE8F3EA),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
