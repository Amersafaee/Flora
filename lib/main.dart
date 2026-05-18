
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/wiki_screen.dart';
import 'screens/flora_chats_list_screen.dart';
import 'screens/all_plants_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Set a stable transparent status bar baseline.
  // The exact icon brightness is updated later based on theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, 
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  debugPrint('Firebase ready');
  // Health score refresh is deferred to after sign-in (see _DigitalConservatoryAppState)

  // Init local notifications safely
  try {
    await NotificationService().initialize();
    await NotificationService().scheduleDailyFloraInsight();
  } catch (e) {
    debugPrint('Warning: Notification initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: DigitalConservatoryApp(),
    ),
  );
}

class DigitalConservatoryApp extends StatefulWidget {
  const DigitalConservatoryApp({super.key});

  @override
  State<DigitalConservatoryApp> createState() => _DigitalConservatoryAppState();
}

class _DigitalConservatoryAppState extends State<DigitalConservatoryApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    // _authStream is initialized once here and never recreated — this is
    // intentional to prevent StreamBuilder from resubscribing on every rebuild
    // which was the root cause of the "sign-in spins forever" bug.
    _authStream = FirebaseAuth.instance.authStateChanges();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await ThemeService().loadThemeMode();
    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    _applySystemUiOverlay(isDark);
  }

  void _onThemeChanged(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    _applySystemUiOverlay(isDark);
  }

  /// Keeps status bar icon brightness in sync with the app theme so that
  /// Flutter's PlatformPlugin does not fight against our initial setting.
  void _applySystemUiOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Conservatory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return MainTabScreen(onThemeChanged: _onThemeChanged);
          }
          return SignupScreen(onThemeChanged: _onThemeChanged);
        },
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  const MainTabScreen({super.key, required this.onThemeChanged});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _builtScreens = {};

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return HomeScreen(onThemeChanged: widget.onThemeChanged);
      case 1: return const AllPlantsScreen();
      case 2: return const FloraChatsListScreen();
      case 3: return const WikiScreen();
      case 4: return const ProfileScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_builtScreens.containsKey(_currentIndex)) {
      _builtScreens[_currentIndex] = _buildScreen(_currentIndex);
      _visitedTabs.add(_currentIndex);
    }

    return Scaffold(
      body: _builtScreens[_currentIndex]!,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.bone100,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: isDark ? AppColors.darkForestPrimary : AppColors.forest700,
          unselectedItemColor: isDark ? AppColors.darkTextTertiary : AppColors.bone500,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.yard_outlined),
              activeIcon: Icon(Icons.yard),
              label: 'Garden',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined),
              activeIcon: Icon(Icons.eco),
              label: 'Flora',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}




Future<void> scheduleHealthScoreRefresh() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final plantsQuery = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').get();
      for (var doc in plantsQuery.docs) {
        final data = doc.data();
        if (data.containsKey('healthScore')) {
          await doc.reference.update({
            'previousHealthScore': data['healthScore'],
          });
        }
      }
      await FirestoreService().computeAllHealthScores(uid);
    }
  } catch (e) {
    debugPrint('Health score refresh error: $e');
  }
}
