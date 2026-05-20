import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'login_screen.dart';
import 'badges_screen.dart';
import 'vacation_mode_screen.dart';
import 'notification_settings_screen.dart';
// zones_screen import removed — no navigation button leads there
import 'edit_profile_screen.dart';
import 'collection_personality_screen.dart';
import 'memorial_garden_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;
  const ProfileScreen({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isDarkMode = false;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;
  String _currentLocaleCode = 'en';

  // Language display names in their own language
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ar': 'العربية',
    'fa': 'فارسی',
    'ja': '日本語',
    'ko': '한국어',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'tr': 'Türkçe',
    'pl': 'Polski',
    'sv': 'Svenska',
    'hi': 'हिन्दी',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    LocaleService.getInitialLocale().then((loc) {
      if (mounted) setState(() => _currentLocaleCode = loc.languageCode);
    });
  }

  Future<void> _loadStats() async {
    try {
      final isDark = await ThemeService().loadThemeMode();

      // Load saved profile photo URL from Firestore
      final uid = _auth.currentUser?.uid;
      String? savedPhotoUrl;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        savedPhotoUrl = (doc.data()?['profilePhotoUrl'] ?? doc.data()?['photoUrl']) as String?;
      }

      if (mounted) {
        setState(() {
          _isDarkMode = isDark;
          if (savedPhotoUrl != null && savedPhotoUrl.isNotEmpty) {
            _profilePhotoUrl = savedPhotoUrl;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Ask user: camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).changeProfilePhoto,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppLocalizations.of(context).takeAPhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context).chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile/profile.jpg');

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'profilePhotoUrl': downloadUrl}, SetOptions(merge: true));

      if (mounted) {
        setState(() => _profilePhotoUrl = downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profilePhotoUpdated),
            backgroundColor: AppColors.forest900,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  void _handleSignOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color softGreen = AppColors.forest100;
    
    final user = _auth.currentUser;
    final email = user?.email ?? 'No email';


    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).myProfile,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser?.uid).collection('notifications').where('isRead', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
                            onPressed: () {
                              _showNotificationsSheet(context);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (count > 0)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Avatar and Info — name resolved from Firestore first
              StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                    : const Stream.empty(),
                builder: (context, userSnap) {
                  String displayedName = '';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data = userSnap.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      // Priority: fullName → displayName in Firestore
                      displayedName = (data['fullName'] as String? ?? '').trim();
                      if (displayedName.isEmpty) {
                        displayedName = (data['displayName'] as String? ?? '').trim();
                      }
                    }
                  }
                  // Then FirebaseAuth displayName
                  if (displayedName.isEmpty) {
                    displayedName = (user?.displayName ?? '').trim();
                  }
                  // Never show 'user' — fall back to email prefix
                  if (displayedName.isEmpty) {
                    displayedName = email.split('@').first;
                  }
                  final resolvedInitials = _getInitials(displayedName);

                  return Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: (_profilePhotoUrl == null && user?.photoURL == null) ? AppColors.bone500 : primaryColor,
                                backgroundImage: _profilePhotoUrl != null
                                    ? NetworkImage(_profilePhotoUrl!)
                                    : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                                child: (_profilePhotoUrl == null && user?.photoURL == null)
                                    ? Text(
                                        resolvedInitials,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isUploadingPhoto)
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const BoxDecoration(
                                    color: Colors.black38,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                    ),
                                    child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayedName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.bone500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            ).then((_) => setState(() {}));
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(AppLocalizations.of(context).editProfile, style: TextStyle(color: primaryColor)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Stats Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FutureBuilder<int>(
                      future: _firestoreService.getTotalPlantsCount(),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).plants,
                          primaryColor: primaryColor,
                        );
                      },
                    ),
                    Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    FutureBuilder<int>(
                      future: _firestoreService.getCompletedTasksCount(),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).tasksDone,
                          primaryColor: primaryColor,
                        );
                      },
                    ),
                    Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    FutureBuilder<int>(
                      future: _firestoreService.getTotalJournalEntriesCount(),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).journalEntries,
                          primaryColor: primaryColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Settings Title
              Text(
                AppLocalizations.of(context).settingsHeader,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bone500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings List
              _buildSettingsRow(
                icon: Icons.emoji_events_outlined,
                title: AppLocalizations.of(context).myBadgesAndLevel,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BadgesScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildSettingsRow(
                icon: Icons.notifications_outlined,
                title: AppLocalizations.of(context).notificationSettings,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.wb_sunny_outlined,
                title: AppLocalizations.of(context).vacationMode,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VacationModeScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.dark_mode_outlined,
                title: AppLocalizations.of(context).darkMode,
                softGreen: softGreen,
                primaryColor: primaryColor,
                isToggle: true,
                toggleValue: _isDarkMode,
                onToggle: (val) async {
                  setState(() => _isDarkMode = val);
                  await ThemeService().saveThemeMode(val);
                  if (widget.onThemeChanged != null) {
                    widget.onThemeChanged!(val);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Language selector row
              _buildLanguageRow(
                softGreen: softGreen,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
              FutureBuilder<(String?, WeatherData?)>(
                future: () async {
                  final ws = WeatherService();
                  final city = await ws.getSavedCity();
                  final weather = await ws.getCurrentWeather();
                  return (city, weather);
                }(),
                builder: (context, snapshot) {
                  final city = snapshot.data?.$1;
                  final weather = snapshot.data?.$2;
                  String subtitle = AppLocalizations.of(context).tapToSetYourCity;
                  if (city != null && city.isNotEmpty) {
                    if (weather != null) {
                      subtitle = '$city · ${weather.temperatureCelsius.toStringAsFixed(1)}°C · ${weather.humidity.toStringAsFixed(0)}% humidity';
                    } else {
                      subtitle = city;
                    }
                  }
                  return GestureDetector(
                    onTap: () async {
                      final cityController = TextEditingController(text: city ?? '');
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppLocalizations.of(context).myCity),
                          content: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. London, Tokyo, New York',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(AppLocalizations.of(context).cancel),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final newCity = cityController.text.trim();
                                if (newCity.isNotEmpty) {
                                  final nav = Navigator.of(ctx);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final l10n = AppLocalizations.of(context);
                                  await WeatherService().saveCity(newCity);
                                  if (mounted) {
                                    nav.pop();
                                    setState(() {});
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(l10n.citySetTo(newCity))),
                                    );
                                  }
                                }
                              },
                              child: Text(AppLocalizations.of(context).save),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: softGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_city, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).myCity,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.bone500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.bone500),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.forest900),
                title: Text(AppLocalizations.of(context).plantHistory),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemorialGardenScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology, color: AppColors.forest900),
                title: Text(AppLocalizations.of(context).myCollectionPersonality),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CollectionPersonalityScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // About Title
              Text(
                AppLocalizations.of(context).aboutHeader,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bone500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSettingsRow(
                icon: Icons.info_outline,
                title: AppLocalizations.of(context).digitalConservatoryVersion,
                softGreen: softGreen,
                primaryColor: primaryColor,
                isInfo: true,
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.email_outlined,
                title: AppLocalizations.of(context).sendFeedback,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () async {
                  final url = Uri.parse('mailto:feedback@digitalconservatory.app?subject=App Feedback');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.shield_outlined,
                title: AppLocalizations.of(context).privacyPolicy,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () async {
                  final url = Uri.parse('https://digitalconservatory.app/privacy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              const SizedBox(height: 40),
              
              // Sign Out Button
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _handleSignOut,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).signOut,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageRow({
    required Color softGreen,
    required Color primaryColor,
  }) {
    final currentName = _languageNames[_currentLocaleCode] ?? _currentLocaleCode;
    return GestureDetector(
      onTap: () => _showLanguagePicker(softGreen: softGreen, primaryColor: primaryColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.language, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentName,
                    style: const TextStyle(fontSize: 12, color: AppColors.bone500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.bone500),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker({
    required Color softGreen,
    required Color primaryColor,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(
                      AppLocalizations.of(context).selectLanguage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Language list
                  ...LocaleService.supportedLanguageCodes.map((code) {
                    final name = _languageNames[code] ?? code;
                    final isSelected = code == _currentLocaleCode;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withValues(alpha: 0.12) : softGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? primaryColor : AppColors.bone500,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: primaryColor)
                          : null,
                      onTap: () async {
                        await LocaleService.saveLocale(code);
                        final newLocale = Locale(code);
                        if (widget.onLocaleChanged != null) {
                          widget.onLocaleChanged!(newLocale);
                        }
                        if (mounted) {
                          setState(() => _currentLocaleCode = code);
                        }
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn({
    required String count,
    required String label,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.bone500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required Color softGreen,
    required Color primaryColor,
    bool isToggle = false,
    bool toggleValue = false,
    bool isInfo = false,
    ValueChanged<bool>? onToggle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (isToggle)
            Switch(
              value: toggleValue,
              onChanged: onToggle,
              activeColor: primaryColor,
            )
          else if (!isInfo)
            const Icon(Icons.chevron_right, color: AppColors.bone500),
        ],
      ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return const SizedBox();
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context).notifications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        final qs = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').where('isRead', isEqualTo: false).get();
                        final batch = FirebaseFirestore.instance.batch();
                        for (var doc in qs.docs) {
                          batch.update(doc.reference, {'isRead': true});
                        }
                        await batch.commit();
                      },
                      child: Text(AppLocalizations.of(context).markAllAsRead),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context).noNewNotifications, style: const TextStyle(color: AppColors.bone500)));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isRead = data['isRead'] == true;
                          final message = data['message'] ?? '';
                          final timestamp = data['timestamp'] as Timestamp?;
                          final timeAgo = timestamp != null ? _formatTimestampForNotification(timestamp.toDate()) : AppLocalizations.of(context).justNow;
                          return ListTile(
                            leading: Icon(Icons.notifications, color: isRead ? AppColors.bone500 : Theme.of(context).primaryColor),
                            title: Text(message, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(timeAgo),
                            onTap: () {
                              docs[index].reference.update({'isRead': true});
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestampForNotification(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return AppLocalizations.of(context).minutesAgoShort(difference.inMinutes);
    if (difference.inHours < 24) return AppLocalizations.of(context).hoursAgoShort(difference.inHours);
    if (difference.inDays < 2) return AppLocalizations.of(context).yesterday;
    return '${difference.inDays} ${AppLocalizations.of(context).daysAgo}';
  }
}





