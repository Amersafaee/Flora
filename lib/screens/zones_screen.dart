import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> _addZone(String name) async {
    if (name.trim().isEmpty || _userId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('zones')
        .add({'name': name.trim(), 'timestamp': FieldValue.serverTimestamp()});
  }

  void _editZone(String id, String currentName) {
    final l = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.editZone),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l.zoneName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final messenger = ScaffoldMessenger.of(context);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('zones')
                      .doc(id)
                      .update({'name': newName});
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l.zoneUpdated), backgroundColor: AppColors.successLight),
                  );
                }
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteZone(String id) async {
    if (_userId.isEmpty) return;
    await _firestore.collection('users').doc(_userId).collection('zones').doc(id).delete();
  }

  void _showAddZoneDialog() {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addZone),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l.zoneHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.bone500)),
          ),
          TextButton(
            onPressed: () {
              _addZone(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(l.save, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        title: Text(l.myZones, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _userId.isEmpty
          ? Center(child: Text(l.pleaseLogIn))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(_userId).collection('zones').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(l.somethingWentWrong, style: const TextStyle(color: AppColors.bone500)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text(l.noZonesYet, style: const TextStyle(color: AppColors.bone500)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? l.unknownZone;
                    final id = docs[index].id;
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.home, color: Theme.of(context).primaryColor),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary), onPressed: () => _editZone(id, name)),
                            IconButton(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), onPressed: () => _deleteZone(id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: _showAddZoneDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
