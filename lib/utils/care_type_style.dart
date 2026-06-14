import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

@immutable
class CareTypeStyle {
  final IconData icon;
  final Color iconColor;
  final Color tileColor;

  const CareTypeStyle({
    required this.icon,
    required this.iconColor,
    required this.tileColor,
  });
}

CareTypeStyle careTypeStyle(String type) {
  final lowerType = type.toLowerCase();
  
  IconData icon;
  if (lowerType.contains('water')) {
    icon = Icons.water_drop;
  } else if (lowerType.contains('fertil')) {
    icon = Icons.science;
  } else if (lowerType.contains('mist')) {
    icon = Icons.air;
  } else if (lowerType.contains('repot')) {
    icon = Icons.yard;
  } else if (lowerType.contains('prun')) {
    icon = Icons.content_cut;
  } else if (lowerType.contains('inspect')) {
    icon = Icons.search;
  } else if (lowerType.contains('treat')) {
    icon = Icons.medical_services;
  } else {
    icon = Icons.check_circle_outline;
  }

  return CareTypeStyle(
    icon: icon,
    iconColor: AppColors.forest700,
    tileColor: AppColors.forest700.withValues(alpha: 0.12),
  );
}
