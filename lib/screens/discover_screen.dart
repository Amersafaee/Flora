import 'package:flutter/material.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'wiki_screen.dart';
import 'community_screen.dart';
import 'swap_market_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _currentTab = 0;

  Widget _buildPillButton(int index, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _currentTab == index;
    final bgColor = isActive
        ? AppColors.forest700
        : (isDark ? AppColors.darkSurfaceElevated : AppColors.bone100);
    final textColor = isActive
        ? Colors.white
        : AppColors.bone400;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.bone50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A224A1E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPillButton(0, l.wiki),
                  const SizedBox(width: 8),
                  _buildPillButton(1, l.community),
                  const SizedBox(width: 8),
                  _buildPillButton(2, l.swapMarket),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  WikiScreen(),
                  CommunityScreen(),
                  SwapMarketScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
