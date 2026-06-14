import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// A standard ALL-CAPS section label in bone400, Outfit 12 w600,
/// letterSpacing 0.8.
///
/// Replaces all inline section header Text widgets across screens.
class SectionHeader extends StatelessWidget {
  final String label;

  const SectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.bone400,
        letterSpacing: 0.8,
      ),
    );
  }
}
