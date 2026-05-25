import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'create_listing_screen.dart';
import '../theme/app_theme.dart';

class FamilyTreeScreen extends StatefulWidget {
  final String plantId;
  final String plantName;

  const FamilyTreeScreen({
    super.key,
    required this.plantId,
    required this.plantName,
  });

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current user's UID, or null if not signed in.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Scoped reference to this user's lineage sub-collection.
  CollectionReference? get _lineageRef {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('lineage');
  }

  // ---------------------------------------------------------------------------
  // Record Parent Plant dialog — picker from user's existing plants
  // ---------------------------------------------------------------------------
  void _showRecordParentDialog() {
    final l = AppLocalizations.of(context);
    final uid = _uid;
    if (uid == null) return;

    // Load user's plants for the picker
    final plantsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .orderBy('name');

    showDialog(
      context: context,
      builder: (context) {
        String? selectedPlantId;
        String? selectedPlantName;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l.recordParentPlant,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              backgroundColor: AppColors.white,
              content: FutureBuilder<QuerySnapshot>(
                future: plantsRef.get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  // Exclude the current plant from the parent picker
                  final filtered = docs
                      .where((d) => d.id != widget.plantId)
                      .toList();

                  if (filtered.isEmpty) {
                    return Text(
                      l.noPlantsFound,
                      style: const TextStyle(color: AppColors.bone500),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedPlantId,
                    hint: Text(
                      l.recordParentHint,
                      style: const TextStyle(color: AppColors.bone300),
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.forest900, width: 2),
                      ),
                    ),
                    items: filtered.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          data['name']?.toString() ?? 'Unknown';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final doc =
                          filtered.firstWhere((d) => d.id == value);
                      final data = doc.data() as Map<String, dynamic>;
                      setDialogState(() {
                        selectedPlantId = value;
                        selectedPlantName =
                            data['name']?.toString() ?? 'Unknown';
                      });
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel,
                      style:
                          const TextStyle(color: AppColors.bone500)),
                ),
                ElevatedButton(
                  onPressed: selectedPlantId == null
                      ? null
                      : () async {
                          await _lineageRef?.add({
                            'parentPlantId': selectedPlantId,
                            'parentPlantName': selectedPlantName,
                            'childPlantId': widget.plantId,
                            'childPlantName': widget.plantName,
                            'dateRecorded':
                                FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest900),
                  child: Text(l.save,
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Add Propagation dialog — text field for new plant name
  // ---------------------------------------------------------------------------
  void _showAddPropagationDialog() {
    final l = AppLocalizations.of(context);
    final TextEditingController childNameController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l.addPropagation,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: AppColors.white,
          content: TextField(
            controller: childNameController,
            decoration: InputDecoration(
              hintText: l.propagationHint,
              hintStyle:
                  const TextStyle(color: AppColors.bone300),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.forest900, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel,
                  style: const TextStyle(color: AppColors.bone500)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = childNameController.text.trim();
                if (name.isNotEmpty) {
                  // Store plantId as '' — will be linked when/if the
                  // propagation is saved as its own plant.
                  await _lineageRef?.add({
                    'parentPlantId': widget.plantId,
                    'parentPlantName': widget.plantName,
                    'childPlantId': '',
                    'childPlantName': name,
                    'dateRecorded': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);

                    final lSheet = AppLocalizations.of(context);
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20))),
                      builder: (sheetContext) {
                        final ls =
                            AppLocalizations.of(sheetContext);
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  lSheet.listCuttingForSwap,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Share your ${widget.plantName} cutting with the community',
                                  style: const TextStyle(
                                      color: AppColors.bone500,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CreateListingScreen(
                                                initialPlantName:
                                                    name),
                                      ),
                                    );
                                  },
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.forest900,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 16),
                                    shape:
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(12)),
                                  ),
                                  child: Text(
                                    ls.listForSwap,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(sheetContext),
                                  child: Text(
                                    ls.notNow,
                                    style: const TextStyle(
                                        color: AppColors.bone500,
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                } else {
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest900),
              child: Text(l.save,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const Color primaryColor = AppColors.forest900;
    const Color backgroundColor = AppColors.bone25;
    const Color softGreen = AppColors.forest100;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    final uid = _uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.plantFamilyTree,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(widget.plantName,
                style: const TextStyle(
                    color: AppColors.bone500, fontSize: 14)),
            const SizedBox(height: 32),
            Expanded(
              child: uid == null
                  ? Center(
                      child: Text(
                        l.notSignedIn,
                        style:
                            const TextStyle(color: AppColors.bone500),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(uid)
                          .collection('lineage')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              l.couldNotLoadFamilyTree,
                              style: const TextStyle(
                                  color: AppColors.bone500),
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Find parent (where childPlantId == widget.plantId)
                        final parentDocs = docs
                            .where((d) =>
                                d['childPlantId'] == widget.plantId)
                            .toList();
                        final Map<String, dynamic>? parentData =
                            parentDocs.isNotEmpty
                                ? parentDocs.first.data()
                                    as Map<String, dynamic>
                                : null;

                        // Find children (where parentPlantId == widget.plantId)
                        final childDocs = docs
                            .where((d) =>
                                d['parentPlantId'] == widget.plantId)
                            .toList();

                        return SingleChildScrollView(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Parent Node
                                if (parentData != null)
                                  Column(
                                    children: [
                                      Text(
                                        l.parentPlantLabel,
                                        style: const TextStyle(
                                            color: AppColors.bone500,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12),
                                        decoration: BoxDecoration(
                                            color: softGreen,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12)),
                                        child: Text(
                                          parentData[
                                                  'parentPlantName'] ??
                                              l.unknownParent,
                                          style: const TextStyle(
                                              color: primaryColor,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      _buildVerticalLine(),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildDashedPlaceholder(
                                          l.noParentRecorded),
                                      _buildVerticalLine(),
                                    ],
                                  ),

                                // Root Node (Current Plant)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                            alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.plantName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),

                                // Children Nodes
                                if (childDocs.isNotEmpty)
                                  Column(
                                    children: [
                                      _buildVerticalLine(),
                                      for (var child in childDocs) ...[
                                        Text(
                                          l.propagatedFromThis,
                                          style: const TextStyle(
                                              color: AppColors.bone500,
                                              fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .cardColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: primaryColor,
                                                width: 1.5),
                                          ),
                                          child: Text(
                                            (child.data() as Map<
                                                        String,
                                                        dynamic>)[
                                                    'childPlantName'] ??
                                                l.unknownProp,
                                            style: TextStyle(
                                                color: textColor,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                        ),
                                        if (childDocs.last != child)
                                          const SizedBox(height: 16),
                                      ],
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildVerticalLine(),
                                      _buildDashedPlaceholder(
                                          l.noPropagationsYet),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showRecordParentDialog,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)),
                      ),
                      child: Text(
                        l.recordParentPlant,
                        style: const TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showAddPropagationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        l.addPropagation,
                        style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Container(width: 2, height: 30, color: AppColors.bone300);
  }

  Widget _buildDashedPlaceholder(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bone300, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.bone500,
            fontStyle: FontStyle.italic,
            fontSize: 14),
      ),
    );
  }
}
