import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notifCare = true;
  bool _notifChat = true;
  bool _notifSwap = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final hour = prefs.getInt('reminder_hour') ?? 9;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _notifCare = prefs.getBool('notif_care') ?? true;
      _notifChat = prefs.getBool('notif_chat') ?? true;
      _notifSwap = prefs.getBool('notif_swap') ?? true;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _savePref('reminder_hour', picked.hour);
      await _savePref('reminder_minute', picked.minute);
    }
  }

  Future<void> _editNameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final ctrl = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name', style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your name'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await user.updateDisplayName(ctrl.text.trim());
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'displayName': ctrl.text.trim(),
                });
                if (context.mounted) {
                  context.pop();
                }
                setState(() {}); // Refresh UI
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/sign-in');
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete your account, plants, chats, and swap listings. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Simplified client-side deletion for MVP
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        // Function to delete a subcollection
        Future<void> deleteSubcollection(String name) async {
          final docs = await userRef.collection(name).get();
          for (final d in docs.docs) {
            await d.reference.delete();
          }
        }

        // Delete all data
        await Future.wait([
          deleteSubcollection('plants'),
          deleteSubcollection('tasks'),
          deleteSubcollection('wishlist'),
          deleteSubcollection('chats'),
        ]);

        await userRef.delete();
        await user.delete();
        if (mounted) context.go('/welcome');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2D5A27), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, duration: const Duration(seconds: 3), ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = user?.displayName?.isNotEmpty == true ? user!.displayName!.substring(0, 1).toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.w700)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // ── 1. Profile ────────────────────────────────────────────────
              Text('Profile', style: TextStyle(color: AppColors.moss, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.cardShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.dew,
                      child: Text(initials, style: const TextStyle(fontSize: 24, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? 'Plant Lover', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: AppColors.moss)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.moss),
                      onPressed: _editNameDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── 2. Notifications ──────────────────────────────────────────
              Text('Notifications', style: TextStyle(color: AppColors.moss, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Daily Care Reminder',
                trailing: Text(_reminderTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.forestGreen)),
                onTap: _pickReminderTime,
              ),
              const SizedBox(height: 8),
              _SettingsToggle(
                icon: Icons.water_drop_outlined,
                title: 'Care Tasks',
                value: _notifCare,
                onChanged: (v) {
                  setState(() => _notifCare = v);
                  _savePref('notif_care', v);
                },
              ),
              const SizedBox(height: 8),
              _SettingsToggle(
                icon: Icons.chat_bubble_outline,
                title: 'Flora Chat Messages',
                value: _notifChat,
                onChanged: (v) {
                  setState(() => _notifChat = v);
                  _savePref('notif_chat', v);
                },
              ),
              const SizedBox(height: 8),
              _SettingsToggle(
                icon: Icons.swap_horiz_rounded,
                title: 'Swap Market Messages',
                value: _notifSwap,
                onChanged: (v) {
                  setState(() => _notifSwap = v);
                  _savePref('notif_swap', v);
                },
              ),
              const SizedBox(height: 32),

              // ── 3. App ───────────────────────────────────────────────────
              Text('App', style: TextStyle(color: AppColors.moss, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.favorite_border,
                title: 'My Wishlist',
                onTap: () => context.push('/wishlist'),
              ),
              const SizedBox(height: 32),

              // ── 4. About ─────────────────────────────────────────────────
              Text('About', style: TextStyle(color: AppColors.moss, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'App Version',
                trailing: const Text('1.0.0', style: TextStyle(color: AppColors.moss)),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _openUrl('https://flora-99ff7.web.app/privacy.html'), // Assuming hosted here
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _openUrl('https://flora-99ff7.web.app/terms.html'),
              ),
              const SizedBox(height: 32),

              // ── 5. Account ───────────────────────────────────────────────
              Text('Account', style: TextStyle(color: AppColors.moss, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: _signOut,
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                textColor: AppColors.terracotta,
                iconColor: AppColors.terracotta,
                onTap: _deleteAccount,
              ),
              const SizedBox(height: 48),
            ],
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      onTap: onTap,
      tileColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      leading: Icon(icon, color: iconColor ?? AppColors.moss),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor ?? (isDark ? Colors.white : AppColors.bark))),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.mist) : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      tileColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      leading: Icon(icon, color: AppColors.moss),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.bark)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.forestGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}


