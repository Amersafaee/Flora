import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

/// Returns the best available profile photo URL for the current user.
/// Prefers the Firestore profilePhotoUrl over Firebase Auth photoURL.
Future<String?> getUserProfilePhotoUrl() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final firestoreUrl = doc.data()?['profilePhotoUrl'] as String?;
    if (firestoreUrl != null && firestoreUrl.isNotEmpty) return firestoreUrl;
  } catch (_) {}
  return FirebaseAuth.instance.currentUser?.photoURL;
}

/// Builds a CircleAvatar for the current logged-in user that correctly
/// resolves the profile photo from Firestore first, then Firebase Auth.
Widget buildUserAvatar({
  double radius = 20,
  Color backgroundColor = AppColors.bone500,
}) {
  return FutureBuilder<String?>(
    future: getUserProfilePhotoUrl(),
    builder: (context, snapshot) {
      final url = snapshot.data;
      if (url != null && url.isNotEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(url),
          backgroundColor: backgroundColor,
        );
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.person, color: Colors.white, size: radius),
      );
    },
  );
}
