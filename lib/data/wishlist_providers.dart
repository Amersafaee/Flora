import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stream of wishlisted species IDs
final wishlistProvider = StreamProvider<Set<String>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(<String>{});

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('wishlist')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

// Toggle wishlist status
Future<void> toggleWishlist(String speciesId, bool isCurrentlyWishlisted) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('wishlist')
      .doc(speciesId);

  if (isCurrentlyWishlisted) {
    await docRef.delete();
  } else {
    await docRef.set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}

