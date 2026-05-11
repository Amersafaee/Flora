import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Compresses [image] if it is larger than 200 KB, resizing to a max width
  /// of 800 px at 70% quality. Returns the original file if already small.
  Future<File> _compressIfNeeded(File image) async {
    final sizeBytes = await image.length();
    // Skip compression for files already under 200 KB
    if (sizeBytes < 200 * 1024) return image;

    final dir = await getTemporaryDirectory();
    final ext = p.extension(image.path).toLowerCase();
    final targetPath =
        p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed$ext');

    final CompressFormat format =
        ext == '.png' ? CompressFormat.png : CompressFormat.jpeg;

    final result = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      minWidth: 800,
      minHeight: 800,
      quality: 70,
      format: format,
    );

    if (result == null) return image; // Fallback to original on failure
    return File(result.path);
  }

  Future<String?> uploadPlantPhoto(File image, String plantId, BuildContext context) async {
    final uid = currentUserId;
    if (uid == null) {
      _showError(context, 'User not logged in');
      return null;
    }

    try {
      final compressed = await _compressIfNeeded(image);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$uid/plants/$plantId/$timestamp.jpg');

      final uploadTask = await ref.putFile(compressed);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Photo upload failed. Please try again.');
      }
      return null;
    }
  }

  Future<String?> uploadGrowthPhoto(File image, String plantId, BuildContext context) async {
    final uid = currentUserId;
    if (uid == null) {
      _showError(context, 'User not logged in');
      return null;
    }

    try {
      final compressed = await _compressIfNeeded(image);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$uid/plants/$plantId/growth/$timestamp.jpg');

      final uploadTask = await ref.putFile(compressed);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Photo upload failed. Please try again.');
      }
      return null;
    }
  }

  Future<String?> uploadPostPhoto(File image, String postId, BuildContext context) async {
    try {
      final compressed = await _compressIfNeeded(image);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('posts/$postId/$timestamp.jpg');

      final uploadTask = await ref.putFile(compressed);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Photo upload failed. Please try again.');
      }
      return null;
    }
  }

  Future<void> deletePhoto(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignored for now
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
