import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An outlined pill-shaped button in Terracotta.
/// Use this for secondary actions like "Cancel", "Skip", "Later".
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        side: const BorderSide(color: AppColors.terracotta, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.terracotta,
                ),
          ),
        ],
      ),
    );
  }
}

