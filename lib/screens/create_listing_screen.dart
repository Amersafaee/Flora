import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateListingScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialDescription;
  final String? initialType;
  final int? initialHealthScore;

  const CreateListingScreen({
    super.key,
    this.initialPlantName,
    this.initialDescription,
    this.initialType,
    this.initialHealthScore,
  });

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final TextEditingController _lookingForController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialPlantName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    if (widget.initialType != null && _types.contains(widget.initialType)) {
      _selectedType = widget.initialType!;
    }
  }
  
  String _selectedType = 'Cutting';
  bool _isLoading = false;

  final List<String> _types = ['Cutting', 'Free Seeds', 'Whole Plant', 'Adoption'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lookingForController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveListing() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, description, and location are required.'), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      int? healthScore = widget.initialHealthScore;
      String? healthStatus;
      String? plantId;

      final plantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plants')
          .where('name', isEqualTo: title)
          .limit(1)
          .get();

      if (plantsSnap.docs.isNotEmpty) {
        final plantDoc = plantsSnap.docs.first;
        final plantData = plantDoc.data();
        healthScore ??= plantData['healthScore'] as int?;
        healthStatus = plantData['healthStatus'] as String?;
        plantId = plantDoc.id;
      }

      final listingData = {
        'ownerUid': user.uid,
        'ownerName': user.displayName ?? 'Local Swapper',
        'title': title,
        'description': description,
        'type': _selectedType,
        'imageUrl': '',
        'lookingFor': _lookingForController.text.trim(),
        'location': location,
        'distanceKm': 0, // Mock distance
        'timestamp': FieldValue.serverTimestamp(),
        'isAvailable': true,
      };

      if (healthScore != null) listingData['healthScore'] = healthScore;
      if (healthStatus != null) listingData['healthStatus'] = healthStatus;
      if (plantId != null) listingData['plantId'] = plantId;

      await FirebaseFirestore.instance.collection('swap_listings').add(listingData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save listing.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Your Plant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : TextButton(
                  onPressed: _saveListing,
                  child: Text('Save', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Monstera Albo cutting',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) => ChoiceChip(
                label: Text(type),
                selected: _selectedType == type,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedType = type);
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(color: _selectedType == type ? Colors.white : Theme.of(context).colorScheme.onSurface),
              )).toList(),
            ),
            const SizedBox(height: 24),
            
            Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your plant or cutting',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Looking For', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _lookingForController,
              decoration: InputDecoration(
                hintText: 'e.g. Rare Philodendrons or leave empty if free',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. North London',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
