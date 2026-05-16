import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';

class AddSwapScreen extends StatefulWidget {
  const AddSwapScreen({super.key});

  @override
  State<AddSwapScreen> createState() => _AddSwapScreenState();
}

class _AddSwapScreenState extends State<AddSwapScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _selectedType = 'cutting';
  bool _isFree = false;
  bool _isLoadingLoc = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLoc = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied');
      }
      
      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      
      if (placemarks.isNotEmpty) {
        _cityCtrl.text = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Unknown City';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not detect location: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, duration: const Duration(seconds: 3), ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Compute geohash from city (roughly). 
      // For MVP, we will try to geocode the city string to get lat/lng.
      double lat = 0.0;
      double lng = 0.0;
      try {
        final locs = await locationFromAddress(city);
        if (locs.isNotEmpty) {
          lat = locs.first.latitude;
          lng = locs.first.longitude;
        }
      } catch (e) {
        // Fallback to current location if city geocoding fails
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }

      final geohash = GeoHasher().encode(lng, lat, precision: 5);
      final name = user.displayName ?? 'Plant Lover';
      final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

      await FirebaseFirestore.instance.collection('swap_listings').add({
        'ownerUid': user.uid,
        'ownerName': name,
        'ownerInitials': initials,
        'type': _selectedType,
        'title': title,
        'description': desc,
        'imageUrl': 'https://source.unsplash.com/400x300/?$title plant',
        'isFree': _isFree,
        'city': city,
        'geohash': geohash,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing posted successfully! 🌱', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF2D5A27), behavior: SnackBarBehavior.floating));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post listing: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Your Plant', style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What are you offering?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChip(label: 'Cutting', value: 'cutting', groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Seeds', value: 'seeds', groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Whole Plant', value: 'whole_plant', groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v)),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('This item is free', style: TextStyle(fontWeight: FontWeight.w500)),
              value: _isFree,
              onChanged: (val) => setState(() => _isFree = val ?? false),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.forestGreen,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Variegated Monstera Cutting',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the condition, size, or what you want in exchange...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g. Seattle, WA',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoadingLoc ? null : _detectLocation,
                  icon: _isLoadingLoc 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: AppColors.forestGreen),
                  tooltip: 'Detect Location',
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _TypeChip({required this.label, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      selectedColor: AppColors.forestGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.bark),
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.dew,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
      side: BorderSide.none,
    );
  }
}


