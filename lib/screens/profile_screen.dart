import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/section_header.dart';
import 'badges_screen.dart';
import 'collection_personality_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'memorial_garden_screen.dart';
import 'notification_settings_screen.dart';
import 'vacation_mode_screen.dart';

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
  File? _pickedImageFile;
  String _currentLocaleCode = 'en';

  // Language display names in their own language
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'EspaÃ±ol',
    'fr': 'FranÃ§ais',
    'de': 'Deutsch',
    'pt': 'PortuguÃªs',
    'ar': 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©',
    'fa': 'ÙØ§Ø±Ø³ÛŒ',
    'ja': 'æ—¥æœ¬èªž',
    'ko': 'í•œêµ­ì–´',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'tr': 'TÃ¼rkÃ§e',
    'pl': 'Polski',
    'sv': 'Svenska',
    'hi': 'à¤¹à¤¿à¤¨à¥à¤¦à¥€',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

    // Immediately preview the picked image
    final file = File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _isUploadingPhoto = true;
    });
    try {
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
        setState(() {
          _profilePhotoUrl = downloadUrl;
          _pickedImageFile = null; // clear local preview â€” network URL takes over
        });
        showToast(context, AppLocalizations.of(context).profilePhotoUpdated, isError: false);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Upload failed: $e', isError: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.bone50;
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
                    icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).myProfile,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
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
              
              // Avatar and Info â€” name resolved from Firestore first
              StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                    : const Stream.empty(),
                builder: (context, userSnap) {
                  String displayedName = '';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data = userSnap.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      // Priority: fullName â†’ displayName in Firestore
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
                  // Never show 'user' â€” fall back to email prefix
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
                                backgroundColor: (_pickedImageFile == null && _profilePhotoUrl == null && user?.photoURL == null) ? AppColors.bone500 : primaryColor,
                                backgroundImage: _pickedImageFile != null
                                    ? FileImage(_pickedImageFile!) as ImageProvider
                                    : _profilePhotoUrl != null
                                        ? NetworkImage(_profilePhotoUrl!)
                                        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                                child: (_pickedImageFile == null && _profilePhotoUrl == null && user?.photoURL == null)
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
              
              // Stats Box (FIX 1)
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _firestoreService.getTotalPlantsCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          icon: Icons.local_florist,
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).plants,
                          backgroundColor: AppColors.forest100,
                          iconColor: AppColors.forest600,
                          darkBackgroundColor: AppColors.darkForestTint,
                          darkIconColor: AppColors.darkForestPrimary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _firestoreService.getCompletedTasksCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          icon: Icons.check_circle_outline,
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).tasksDone,
                          backgroundColor: AppColors.terracotta100,
                          iconColor: AppColors.terracotta700,
                          darkBackgroundColor: AppColors.darkTerracottaTint,
                          darkIconColor: AppColors.darkTerracotta,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _firestoreService.getTotalJournalEntriesCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          icon: Icons.book_outlined,
                          count: snapshot.hasData ? snapshot.data.toString() : '...',
                          label: AppLocalizations.of(context).journalEntries,
                          backgroundColor: const Color(0xFFE8F0F8),
                          iconColor: const Color(0xFF4A6FA5),
                          darkBackgroundColor: AppColors.darkSlateBlueTint,
                          darkIconColor: AppColors.slateBlue500,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Settings Title (FIX 4)
              SectionHeader(AppLocalizations.of(context).settingsHeader),
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
                  if (!mounted) return;
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
              FutureBuilder<(String?, WeatherData?, bool)>(
                future: () async {
                  final ws = WeatherService();
                  final city = await ws.getSavedCity();
                  final weather = await ws.getCurrentWeather();
                  final useAuto = await ws.getUseAutoLocation();
                  return (city, weather, useAuto);
                }(),
                builder: (context, snapshot) {
                  final city = snapshot.data?.$1;
                  final weather = snapshot.data?.$2;
                  final useAuto = snapshot.data?.$3 ?? false;

                  String subtitle;
                  if (useAuto) {
                    if (weather != null) {
                      subtitle =
                          'Auto Â· ${weather.cityName} Â· ${weather.temperatureCelsius.toStringAsFixed(1)}Â°C Â· ${weather.humidity.toStringAsFixed(0)}% humidity';
                    } else {
                      subtitle = AppLocalizations.of(context).detectAutomatically;
                    }
                  } else if (city != null && city.isNotEmpty) {
                    if (weather != null) {
                      subtitle =
                          '$city Â· ${weather.temperatureCelsius.toStringAsFixed(1)}Â°C Â· ${weather.humidity.toStringAsFixed(0)}% humidity';
                    } else {
                      subtitle = city;
                    }
                  } else {
                    subtitle = AppLocalizations.of(context).tapToSetYourCity;
                  }

                  return GestureDetector(
                    onTap: () async {
                      final cityController =
                          TextEditingController(text: city ?? '');
                      bool dialogUseAuto = useAuto;

                      await showDialog(
                        context: context,
                        builder: (ctx) => StatefulBuilder(
                          builder: (ctx, setDialogState) => AlertDialog(
                            backgroundColor: AppColors.bone50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title:
                                Text(AppLocalizations.of(context).myCity),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Detect automatically option
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setDialogState(() =>
                                        dialogUseAuto = !dialogUseAuto);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: dialogUseAuto
                                          ? AppColors.forest100
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.4),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: dialogUseAuto
                                            ? AppColors.forest700
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.my_location,
                                          color: dialogUseAuto
                                              ? AppColors.forest700
                                              : AppColors.bone500,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context).detectAutomatically,
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 14,
                                                  color: dialogUseAuto
                                                      ? AppColors.forest700
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                ),
                                              ),
                                              Text(
                                                AppLocalizations.of(context).usesYourIpAddress,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.bone500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (dialogUseAuto)
                                          const Icon(Icons.check_circle,
                                              color: AppColors.forest700,
                                              size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Divider with OR label
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color:
                                                AppColors.bone200)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text('or',
                                          style: TextStyle(
                                              color: AppColors.bone500,
                                              fontSize: 12)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color:
                                                AppColors.bone200)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Manual city text field
                                TextField(
                                  controller: cityController,
                                  onTap: () {
                                    if (dialogUseAuto) {
                                      setDialogState(
                                          () => dialogUseAuto = false);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g. London, Tokyo, New York',
                                    prefixIcon: const Icon(Icons.location_city),
                                    filled: true,
                                    fillColor: AppColors.bone100,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.bone200, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(AppLocalizations.of(context)
                                    .cancel),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.forest700,
                                ),
                                onPressed: () async {
                                  final nav = Navigator.of(ctx);
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final l10n =
                                      AppLocalizations.of(context);
                                  final ws = WeatherService();

                                  if (dialogUseAuto) {
                                    await ws.saveAutoLocation(true);
                                    if (mounted) {
                                      nav.pop();
                                      setState(() {});
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              l10n.detectAutomatically),
                                        ),
                                      );
                                    }
                                  } else {
                                    final newCity =
                                        cityController.text.trim();
                                    if (newCity.isNotEmpty) {
                                      await ws.saveCity(newCity);
                                      if (mounted) {
                                        nav.pop();
                                        setState(() {});
                                        messenger.showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  l10n.citySetTo(newCity))),
                                        );
                                      }
                                    } else {
                                      nav.pop();
                                    }
                                  }
                                },
                                child: Text(
                                    AppLocalizations.of(context).save),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            useAuto
                                ? Icons.my_location
                                : Icons.location_city,
                            color: AppColors.forest600,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).myCity,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
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
                          const Icon(Icons.chevron_right,
                              color: AppColors.bone500),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.history,
                title: AppLocalizations.of(context).plantHistory,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemorialGardenScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.psychology,
                title: AppLocalizations.of(context).myCollectionPersonality,
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CollectionPersonalityScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),
              
              // About Title (FIX 4)
              SectionHeader(AppLocalizations.of(context).aboutHeader),
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
              
              // Sign Out Button (FIX 3)
              Center(
                child: TextButton(
                  onPressed: _handleSignOut,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.bone500,
                  ),
                  child: Text(
                    AppLocalizations.of(context).signOut,
                    style: const TextStyle(
                      color: AppColors.bone500,
                      fontSize: 15,
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
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.language, color: AppColors.forest600, size: 24),
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: LocaleService.supportedLanguageCodes.map((code) {
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
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    Color? darkBackgroundColor,
    Color? darkIconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = isDark ? (darkBackgroundColor ?? AppColors.darkCardSurface) : backgroundColor;
    final effectiveIcon = isDark ? (darkIconColor ?? AppColors.darkForestPrimary) : iconColor;
    final countColor = isDark ? AppColors.darkTextPrimary : AppColors.bone900;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.bone500;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: AppColors.darkCardBorder, width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveIcon, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            ),
          ),
        ],
      ),
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
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.forest600, size: 24),
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
                activeTrackColor: AppColors.switchActiveTrack,
                activeThumbColor: AppColors.switchThumb,
                inactiveTrackColor: AppColors.switchInactiveTrack,
                inactiveThumbColor: AppColors.switchThumb,
                trackOutlineColor: AppColors.switchTrackOutline,
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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





