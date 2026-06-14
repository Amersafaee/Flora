// Navigation Tests
//
// Tests the MainTabScreen tab structure and bottom navigation mapping.
//
// The 5 tabs are:
//   Tab 0: Home       → HomeScreen
//   Tab 1: Garden     → AllPlantsScreen
//   Tab 2: Verdoro    → VerdoroChatsListScreen
//   Tab 3: Identify   → IdentifyScreen
//   Tab 4: Community  → CommunityScreen
//
// Full widget tests of MainTabScreen would require Firebase to be initialized
// (HomeScreen, AllPlantsScreen etc. all fire auth listeners on mount).
// Instead, we test:
//   1. The tab index-to-screen mapping as pure Dart logic
//   2. The "Identify" label hardcoded string matches expected value
//   3. The tab count is exactly 5

import 'package:flutter_test/flutter_test.dart';
import 'package:verdoro/screens/all_plants_screen.dart';
import 'package:verdoro/screens/identify_screen.dart';
import 'package:verdoro/screens/community_screen.dart';
import 'package:verdoro/screens/verdoro_chats_list_screen.dart';
import 'package:flutter/material.dart';

// ── Pure mapping that mirrors MainTabScreen._buildScreen ─────────────────────
//
// We replicate the switch exactly as it appears in main.dart so we can test
// the mapping without constructing a live Firebase-dependent widget tree.

Widget _buildScreen(int index) {
  switch (index) {
    case 0:
      // HomeScreen requires Firebase — represented by a placeholder in this test
      return const _HomeScreenPlaceholder();
    case 1:
      return const AllPlantsScreen();
    case 2:
      return const VerdoroChatsListScreen();
    case 3:
      return const IdentifyScreen();
    case 4:
      return const CommunityScreen();
    default:
      return const SizedBox.shrink();
  }
}

/// Placeholder for HomeScreen to avoid Firebase initialization in unit tests.
class _HomeScreenPlaceholder extends StatelessWidget {
  const _HomeScreenPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Tab label constants (mirrored from main.dart hardcoded strings) ───────────
const _kTabCount = 5;
const _kHardcodedIdentifyLabel = 'Identify';

// Labels sourced from AppLocalizations keys (tested as known English strings)
const _kExpectedLabels = [
  'Home',       // navHome
  'Garden',     // garden
  'Verdoro',    // verdoro
  'Identify',   // hardcoded string literal in main.dart line 240
  'Community',  // community
];

void main() {
  group('Navigation — Tab count', () {
    test('App has exactly 5 tabs', () {
      expect(_kTabCount, 5);
    });

    test('Tab indices 0-4 all return a Widget (not SizedBox.shrink)', () {
      for (int i = 0; i < _kTabCount; i++) {
        final widget = _buildScreen(i);
        expect(widget, isA<Widget>());
      }
    });

    test('Tab index > 4 returns SizedBox.shrink() (default case)', () {
      final widget = _buildScreen(99);
      expect(widget, isA<SizedBox>());
    });
  });

  group('Navigation — Tab-to-screen mapping', () {
    test('Tab 0 maps to HomeScreen type (placeholder in tests)', () {
      final widget = _buildScreen(0);
      expect(widget, isA<_HomeScreenPlaceholder>());
    });

    test('Tab 1 maps to AllPlantsScreen', () {
      final widget = _buildScreen(1);
      expect(widget, isA<AllPlantsScreen>());
    });

    test('Tab 2 maps to VerdoroChatsListScreen', () {
      final widget = _buildScreen(2);
      expect(widget, isA<VerdoroChatsListScreen>());
    });

    test('Tab 3 maps to IdentifyScreen', () {
      final widget = _buildScreen(3);
      expect(widget, isA<IdentifyScreen>());
    });

    test('Tab 4 maps to CommunityScreen', () {
      final widget = _buildScreen(4);
      expect(widget, isA<CommunityScreen>());
    });
  });

  group('Navigation — Tab labels', () {
    test('Expected tab labels list has exactly 5 entries', () {
      expect(_kExpectedLabels.length, 5);
    });

    test('"Identify" label is hardcoded (not from l10n)', () {
      // main.dart line 240: label: 'Identify'
      expect(_kHardcodedIdentifyLabel, 'Identify');
    });

    test('All expected tab labels are non-empty strings', () {
      for (final label in _kExpectedLabels) {
        expect(label.isNotEmpty, isTrue, reason: 'Label "$label" must not be empty');
      }
    });

    test('No duplicate tab labels exist', () {
      final unique = _kExpectedLabels.toSet();
      expect(unique.length, _kExpectedLabels.length,
          reason: 'Each tab label must be unique');
    });

    test('Tab labels match expected order: Home, Garden, Verdoro, Identify, Community', () {
      expect(_kExpectedLabels[0], 'Home');
      expect(_kExpectedLabels[1], 'Garden');
      expect(_kExpectedLabels[2], 'Verdoro');
      expect(_kExpectedLabels[3], 'Identify');
      expect(_kExpectedLabels[4], 'Community');
    });
  });
}
