import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (user == null) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('users/${user!.uid}/profile_photo.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      
      await user!.updatePhotoURL(url);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update photo.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await user!.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': name,
      }, SetOptions(merge: true));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red),
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
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    const Color terracotta = Color(0xFF8D3220);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text('Save', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA1D494), Color(0xFF154212)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: user?.photoURL != null
                        ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                if (_isUploading)
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isUploading ? null : _changePhoto,
              child: Text(
                'Change Photo',
                style: TextStyle(color: terracotta, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            
            // Name Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Display Name', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            
            // Email Field (Read Only)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              readOnly: true,
              style: TextStyle(color: Colors.grey.shade600),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


