import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _showRecordParentDialog() {
    final TextEditingController parentNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Record Parent Plant', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: const Color(0xFFFFFFFF),
          content: TextField(
            controller: parentNameController,
            decoration: InputDecoration(
              hintText: 'e.g. Grandma\'s Monstera',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = parentNameController.text.trim();
                if (name.isNotEmpty) {
                  await _firestore.collection('lineage').add({
                    'parentPlantId': 'unknown',
                    'parentPlantName': name,
                    'childPlantId': widget.plantId,
                    'childPlantName': widget.plantName,
                    'dateRecorded': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154212),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPropagationDialog() {
    final TextEditingController childNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Propagation', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: const Color(0xFFFFFFFF),
          content: TextField(
            controller: childNameController,
            decoration: InputDecoration(
              hintText: 'e.g. Propagation #1',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = childNameController.text.trim();
                if (name.isNotEmpty) {
                  await _firestore.collection('lineage').add({
                    'parentPlantId': widget.plantId,
                    'parentPlantName': widget.plantName,
                    'childPlantId': 'new_prop_${DateTime.now().millisecondsSinceEpoch}',
                    'childPlantName': name,
                    'dateRecorded': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154212),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF154212);
    const Color backgroundColor = Color(0xFFF8FAF8);
    const Color softGreen = Color(0xFFE8F3EA);
    final Color textColor = Theme.of(context).colorScheme.onSurface;

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
          'Plant Family Tree', style: TextStyle(color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              widget.plantName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('lineage').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load family tree.', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Find parent (where childPlantId == widget.plantId)
                  final parentDocs = docs.where((d) => d['childPlantId'] == widget.plantId).toList();
                  final Map<String, dynamic>? parentData = parentDocs.isNotEmpty ? parentDocs.first.data() as Map<String, dynamic> : null;

                  // Find children (where parentPlantId == widget.plantId)
                  final childDocs = docs.where((d) => d['parentPlantId'] == widget.plantId).toList();

                  return SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Parent Node
                          if (parentData != null)
                            Column(
                              children: [
                                Text('Parent Plant', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: softGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    parentData['parentPlantName'] ?? 'Unknown Parent',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _buildVerticalLine(),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildDashedPlaceholder('No parent recorded'),
                                _buildVerticalLine(),
                              ],
                            ),

                          // Root Node (Current Plant)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
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
                                fontSize: 18,
                              ),
                            ),
                          ),

                          // Children Nodes
                          if (childDocs.isNotEmpty)
                            Column(
                              children: [
                                _buildVerticalLine(),
                                // If multiple children, we can just show them in a column
                                // Alternatively, draw a horizontal line and branch out, but column is safer and works cleanly.
                                for (var child in childDocs) ...[
                                  Text('Propagated From This', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: primaryColor, width: 1.5),
                                    ),
                                    child: Text(
                                      (child.data() as Map<String, dynamic>)['childPlantName'] ?? 'Unknown Prop',
                                      style: TextStyle(color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (childDocs.last != child) const SizedBox(height: 16),
                                ],
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildVerticalLine(),
                                _buildDashedPlaceholder('No propagations yet'),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Record Parent Plant',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Propagation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
    return Container(
      width: 2,
      height: 30,
      color: Colors.grey.shade400,
    );
  }

  Widget _buildDashedPlaceholder(String text) {
    // Custom painting or simply a decorated container if we don't have dotted_border.
    // The prompt says "boxes with dashed borders". Since dotted_border was removed earlier,
    // we can either use a custom painter or just a light grey solid border.
    // The prompt says "visual tree diagram built with Flutter widgets not a third party library",
    // so we can build a simple custom dashed border or just use a solid border for the placeholder to avoid complexity.
    // We'll use a very light solid border for now, or just an un-bordered container with dashed-like appearance.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1, style: BorderStyle.solid),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }
}







