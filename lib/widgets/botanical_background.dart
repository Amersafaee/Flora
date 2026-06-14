import 'package:flutter/material.dart';

// TODO: add assets/images/botanical_texture.png to use this widget.
class BotanicalBackground extends StatelessWidget {
  final Widget child;
  const BotanicalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.04 : 0.06,
              child: Image.asset(
                'assets/images/botanical_texture.png',
                fit: BoxFit.cover,
                height: 220,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
