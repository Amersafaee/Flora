import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';
import 'badges_screen.dart';
import 'vacation_mode_screen.dart';
import 'notification_settings_screen.dart';
import 'zones_screen.dart';
import 'edit_profile_screen.dart';
import 'collection_personality_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const ProfileScreen({super.key, this.onThemeChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  int _plantsCount = 0;
  int _tasksCount = 0;
  int _journalCount = 0;
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final plants = await _firestoreService.getTotalPlantsCount();
      final tasks = await _firestoreService.getCompletedTasksCount();
      final journals = await _firestoreService.getTotalJournalEntriesCount();
      final isDark = await ThemeService().loadThemeMode();

      // Load saved profile photo URL from Firestore
      final uid = _auth.currentUser?.uid;
      String? savedPhotoUrl;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        savedPhotoUrl = doc.data()?['profilePhotoUrl'] as String?;
      }

      if (mounted) {
        setState(() {
          _plantsCount = plants;
          _tasksCount = tasks;
          _journalCount = journals;
          _isDarkMode = isDark;
          _isLoading = false;
          if (savedPhotoUrl != null && savedPhotoUrl.isNotEmpty) {
            _profilePhotoUrl = savedPhotoUrl;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
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
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Color(0xFF154212),
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
    const Color softGreen = Color(0xFFE8F3EA);
    
    final user = _auth.currentUser;
    final fullName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';
    final initials = _getInitials(fullName);

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
                        'My Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Balance header
                ],
              ),
              const SizedBox(height: 32),
              
              // Avatar and Info
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: primaryColor,
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                            child: (_profilePhotoUrl == null && user?.photoURL == null)
                                ? Text(
                                    initials,
                                    style: const TextStyle(
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
                              decoration: BoxDecoration(
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
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
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
                        color: Colors.grey,
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
                      child: Text('Edit Profile', style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
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
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          count: _plantsCount.toString(),
                          label: 'Plants',
                          primaryColor: primaryColor,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatColumn(
                          count: _tasksCount.toString(),
                          label: 'Tasks Done',
                          primaryColor: primaryColor,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatColumn(
                          count: _journalCount.toString(),
                          label: 'Journal Entries',
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 32),
              
              // Settings Title
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings List
              _buildSettingsRow(
                icon: Icons.emoji_events_outlined,
                title: 'My Badges and Level',
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
                icon: Icons.auto_awesome,
                title: 'My Gardener Personality',
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CollectionPersonalityScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
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
                title: 'Vacation Mode',
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
                icon: Icons.home_outlined,
                title: 'My Zones',
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ZonesScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
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
              _buildSettingsRow(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                softGreen: softGreen,
                primaryColor: primaryColor,
                onTap: () async {
                  final url = Uri.parse('https://www.termsfeed.com/live/digital-conservatory-privacy');
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
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
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
            color: Colors.grey,
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
          else
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      ),
    );
  }
}





