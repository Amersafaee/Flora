import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current [User?] whenever auth state changes.
/// null  → not signed in
/// User  → signed in
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Convenience: the current user (sync, may be null).
final currentUserProvider = Provider<User?>(
  (ref) => FirebaseAuth.instance.currentUser,
);

