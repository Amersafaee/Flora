import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/identify/identify_screen.dart';
import '../features/care/care_screen.dart';
import '../features/wiki/wiki_screen.dart';
import '../features/wiki/species_detail_screen.dart';
import '../features/swap/swap_screen.dart';
import '../features/swap/add_swap_screen.dart';
import '../features/swap/swap_detail_screen.dart';
import '../features/messaging/message_screen.dart';
import '../data/message_providers.dart';
import '../features/add_plant/add_plant_screen.dart';
import '../features/plant_detail/plant_detail_screen.dart';
import '../features/edit_plant/edit_plant_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/onboarding/intro_carousel_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/wishlist_screen.dart';
import '../features/flora_chat/flora_chat_screen.dart';
import '../theme/tokens.dart';

// ─── Router ─────────────────────────────────────────────────────────────────
// Riverpod-aware router: listens to auth state and redirects accordingly.
GoRouter buildAppRouter(WidgetRef ref) {
  final authNotifier = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());

  // Keep the notifier in sync with auth state changes
  FirebaseAuth.instance.authStateChanges().listen((user) {
    authNotifier.value = AsyncData(user);
  });

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.value;
      final isLoading = auth is AsyncLoading;
      final user = auth.valueOrNull;

      final loc = state.matchedLocation;

      // Don't redirect while auth is resolving
      if (isLoading) return null;

      // Public routes — let them through regardless of auth
      const publicRoutes = ['/welcome', '/intro', '/sign-in'];
      if (publicRoutes.contains(loc)) return null;

      // Not signed in → send to sign-in
      if (user == null) return '/sign-in';

      // Signed in but no Firestore profile yet → profile setup
      // FAST synchronous check instead of blocking Firestore call!
      if (loc != '/profile-setup' && (user.displayName == null || user.displayName!.isEmpty)) {
        return '/profile-setup';
      }

      return null;
    },
    routes: [
      // ── Onboarding / auth (no shell) ──────────────────────────────────
      GoRoute(path: '/welcome',       builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/intro',         builder: (_, __) => const IntroCarouselScreen()),
      GoRoute(path: '/sign-in',       builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

      // ── Extra routes (outside shell) ──────────────────────────────────
      GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/flora-chat', 
        builder: (_, state) => FloraChatScreen(
          initialMessage: state.extra as String?,
        ),
      ),
      GoRoute(path: '/add-plant',  builder: (_, __) => const AddPlantScreen()),
      GoRoute(path: '/wishlist',   builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/add-swap',   builder: (_, __) => const AddSwapScreen()),
      GoRoute(
        path: '/swap/:id',
        builder: (_, state) => SwapDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/messages/:threadId',
        builder: (_, state) => MessageScreen(
          threadId: state.pathParameters['threadId']!,
          otherUserName: state.extra as String? ?? 'Message',
        ),
      ),
      GoRoute(
        path: '/species/:id',
        builder: (_, state) => SpeciesDetailScreen(speciesId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plant/:id',
        builder: (_, state) =>
            PlantDetailScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/edit-plant/:id',
        builder: (_, state) =>
            EditPlantScreen(plantId: state.pathParameters['id']!),
      ),

      // ── 5-tab shell ───────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/identify', builder: (_, __) => const IdentifyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/care',     builder: (_, __) => const CareScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wiki',     builder: (_, __) => const WikiScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/swap',     builder: (_, __) => const SwapScreen()),
          ]),
        ],
      ),
    ],
  );
}

// ─── Shell scaffold ──────────────────────────────────────────────────────────
// Wraps all 5 tabs. Shows the shared AppBar and bottom NavBar.
class _ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx  = navigationShell.currentIndex;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // ── App bar ─────────────────────────────────────────────────────────
      // Spec: left = circular avatar, center = "Flora" in Noto Serif,
      //       right = search icon
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => context.push('/profile-setup'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: AppColors.dew,
              backgroundImage: (user?.photoURL != null)
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: (user?.photoURL == null)
                  ? const Text('🌿', style: TextStyle(fontSize: 18))
                  : null,
            ),
          ),
        ),
        title: const Text(
          'Flora',
          style: TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // Search icon (right side — as specified)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () {
              showSearch(
                context: context,
                delegate: _PlantSearchDelegate(),
              );
            },
          ),
          // Messages icon with unread badge
          Consumer(
            builder: (context, ref, child) {
              final unreadAsync = ref.watch(unreadMessagesProvider);
              final hasUnread = unreadAsync.valueOrNull ?? false;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.forum_outlined),
                    tooltip: 'Messages',
                    onPressed: () => context.push('/swap'), // For MVP, we just direct them to swap
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                      ),
                    ),
                ],
              );
            },
          ),
          // Settings shortcut
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),

      body: navigationShell,

      // ── Bottom nav bar ───────────────────────────────────────────────────
      // Spec: active tab gets a soft leaf-green pill behind the icon,
      //       forest green icon. Inactive tabs are grey.
      bottomNavigationBar: _FloraNavBar(
        currentIndex: idx,
        onTap: (index) =>
            navigationShell.goBranch(index, initialLocation: index == idx),
      ),
    );
  }
}

// ─── Custom bottom nav bar with leaf-green pill ──────────────────────────────
class _FloraNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloraNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_outlined,      Icons.home_rounded,       'Home'),
    _NavItem(Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Identify'),
    _NavItem(Icons.water_drop_outlined, Icons.water_drop_rounded, 'Care'),
    _NavItem(Icons.menu_book_outlined,  Icons.menu_book_rounded,  'Wiki'),
    _NavItem(Icons.swap_horiz_rounded,  Icons.swap_horiz_rounded, 'Swap'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.mist, width: 0.5)),
          ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Pill behind icon ────────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.leafGreen.withAlpha(30)
                              : Colors.transparent,
                          borderRadius: AppRadius.borderLg,
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected
                              ? AppColors.forestGreen
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.forestGreen
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─── Simple plant search delegate ────────────────────────────────────────────
class _PlantSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search plants…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final suggestions = [
      'Monstera', 'Pothos', 'Snake Plant', 'Fiddle-Leaf Fig',
      'Peace Lily', 'Aloe Vera', 'ZZ Plant', 'Rubber Plant',
    ].where((s) => s.toLowerCase().contains(q)).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.eco_outlined, color: AppColors.leafGreen),
        title: Text(suggestions[i]),
        onTap: () => close(context, suggestions[i]),
      ),
    );
  }
}

