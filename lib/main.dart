
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
import 'screens/identify_screen.dart';
import 'screens/care_screen.dart';
import 'screens/community_screen.dart';
import 'screens/wiki_screen.dart';
import 'screens/flora_chats_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _healthRefreshDone = false;
  bool? _onboardingComplete;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _loadTheme();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    });
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
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Something went wrong',
                  style: TextStyle(color: Colors.grey))),
            );
          }
          if (snapshot.hasData) {
            // Defer health score refresh to after auth is confirmed
            if (!_healthRefreshDone) {
              _healthRefreshDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scheduleHealthScoreRefresh();
              });
            }
            return MainTabScreen(onThemeChanged: _onThemeChanged);
          }
          if (_onboardingComplete == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _onboardingComplete! ? const LoginScreen() : const OnboardingScreen();
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
      case 1: return const FloraChatsListScreen();
      case 2: return const IdentifyScreen();
      case 3: return CareScreen(onThemeChanged: widget.onThemeChanged);
      case 4: return const CommunityScreen();
      case 5: return const WikiScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_builtScreens.containsKey(_currentIndex)) {
      _builtScreens[_currentIndex] = _buildScreen(_currentIndex);
      _visitedTabs.add(_currentIndex);
    }

    return Scaffold(
      body: _builtScreens[_currentIndex]!,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
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
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Flora'),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Identify'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Care'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Wiki'),
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
