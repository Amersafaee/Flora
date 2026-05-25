import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _dailyCare = true;
  bool _morningDigest = false;
  bool _urgentAlerts = true;
  bool _communityReplies = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyCare = prefs.getBool('notif_daily_care') ?? true;
      _morningDigest = prefs.getBool('notif_morning_digest') ?? false;
      _urgentAlerts = prefs.getBool('notif_urgent_alerts') ?? true;
      _communityReplies = prefs.getBool('notif_community_replies') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.notificationSettings,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildToggle(l.dailyCareReminders, l.dailyCareRemindersSubtitle, _dailyCare, (val) {
            setState(() => _dailyCare = val);
            _saveSetting('notif_daily_care', val);
          }),
          const Divider(height: 32),
          _buildToggle(l.morningDigest, l.morningDigestSubtitle, _morningDigest, (val) {
            setState(() => _morningDigest = val);
            _saveSetting('notif_morning_digest', val);
          }),
          const Divider(height: 32),
          _buildToggle(l.urgentAlerts, l.urgentAlertsSubtitle, _urgentAlerts, (val) {
            setState(() => _urgentAlerts = val);
            _saveSetting('notif_urgent_alerts', val);
          }),
          const Divider(height: 32),
          _buildToggle(l.communityReplies, l.communityRepliesSubtitle, _communityReplies, (val) {
            setState(() => _communityReplies = val);
            _saveSetting('notif_community_replies', val);
          }),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.bone500)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
