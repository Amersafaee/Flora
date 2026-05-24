// ignore_for_file: avoid_print
// dart run tool/audit_blogs.dart
//
// Connects to Firestore and audits the 'blogs' collection.
// Lists which blogs have images and which need them, together with a
// suggested Unsplash search term derived from each blog's title.

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_conservatory/firebase_options.dart';

// ---------------------------------------------------------------------------
// Unsplash search-term generator
// ---------------------------------------------------------------------------

/// Strips common filler words/phrases and returns a 2-3 word search term
/// suitable for an Unsplash image search.
String _unsplashTerm(String title) {
  var t = title;

  // Remove common title prefixes (case-insensitive)
  const prefixPatterns = [
    r'^How to ',
    r'^A Guide to ',
    r'^The Guide to ',
    r'^Guide to ',
    r'^The Complete Guide to ',
    r'^Complete Guide to ',
    r'^Understanding ',
    r'^Introduction to ',
    r'^Getting Started with ',
    r'^All About ',
    r'^Everything About ',
    r'^The Art of ',
    r'^Tips for ',
    r'^Top \d+ Tips for ',
    r'^Top \d+ ',
    r'^\d+ Ways to ',
    r'^\d+ Tips for ',
    r'^Why ',
    r'^What is ',
    r'^The ',
    r'^A ',
    r'^An ',
  ];

  for (final pat in prefixPatterns) {
    t = t.replaceAll(RegExp(pat, caseSensitive: false), '');
  }

  // Remove trailing punctuation
  t = t.replaceAll(RegExp(r'[?!:,.]$'), '').trim();

  // Remove very common stop words to tighten the phrase
  const stopWords = {
    'your', 'my', 'our', 'their', 'its', 'the', 'a', 'an',
    'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
    'from', 'by', 'up', 'as', 'is', 'are', 'was', 'be',
    'this', 'that', 'these', 'those',
  };

  final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final meaningful = words.where((w) => !stopWords.contains(w.toLowerCase())).toList();

  // Take up to 3 meaningful words, fall back to first 3 raw words if needed
  final selected = meaningful.isNotEmpty ? meaningful.take(3).toList() : words.take(3).toList();

  return selected.join(' ').toLowerCase();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  // Initialise Firebase (same approach as lib/main.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  stdout.writeln('\n🔍  BLOG AUDIT — Flora Firestore\n');
  stdout.writeln('Fetching blogs collection...');

  final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('blogs').get();

  final docs = snapshot.docs;
  stdout.writeln('Total documents fetched: ${docs.length}\n');

  // Partition docs
  final List<Map<String, dynamic>> withImages = [];
  final List<Map<String, dynamic>> withoutImages = [];

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? data['name'] ?? '(no title)').toString();

    // Check any of the three possible image field names
    final imageUrl = _nonEmpty(data['imageUrl'])
        ?? _nonEmpty(data['thumbnailUrl'])
        ?? _nonEmpty(data['image']);

    if (imageUrl != null) {
      withImages.add({
        'id': doc.id,
        'title': title,
        'imageUrl': imageUrl,
      });
    } else {
      withoutImages.add({
        'id': doc.id,
        'title': title,
        'unsplash': _unsplashTerm(title),
      });
    }
  }

  // ── Section 1: blogs WITH images ────────────────────────────────────────
  stdout.writeln('═══════════════════════════════════════════════════════════');
  stdout.writeln('  BLOGS WITH IMAGES (keep as-is): ${withImages.length}');
  stdout.writeln('═══════════════════════════════════════════════════════════');

  if (withImages.isEmpty) {
    stdout.writeln('  (none)');
  } else {
    for (final b in withImages) {
      stdout.writeln('  ✅ ${b['title']}');
      stdout.writeln('     imageUrl: ${b['imageUrl']}');
    }
  }

  // ── Section 2: blogs WITHOUT images ─────────────────────────────────────
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════════');
  stdout.writeln('  BLOGS WITHOUT IMAGES (need images): ${withoutImages.length}');
  stdout.writeln('═══════════════════════════════════════════════════════════');

  if (withoutImages.isEmpty) {
    stdout.writeln('  (none — all blogs have images 🎉)');
  } else {
    for (final b in withoutImages) {
      stdout.writeln('  ❌ ${b['title']}');
      stdout.writeln('     id:       ${b['id']}');
      stdout.writeln('     unsplash: ${b['unsplash']}');
    }
  }

  // ── Summary ──────────────────────────────────────────────────────────────
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════════');
  stdout.writeln('  SUMMARY');
  stdout.writeln('  Total blogs:          ${docs.length}');
  stdout.writeln('  With images:          ${withImages.length}');
  stdout.writeln('  Without images:       ${withoutImages.length}');
  stdout.writeln('═══════════════════════════════════════════════════════════');

  // ── Copy-this-list block ─────────────────────────────────────────────────
  if (withoutImages.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('---COPY THIS LIST---');
    for (final b in withoutImages) {
      stdout.writeln('${b['title']} | ${b['id']} | ${b['unsplash']}');
    }
    stdout.writeln('---END LIST---');
  }

  stdout.writeln('');
  exit(0);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns [value] if it is a non-empty string, otherwise null.
String? _nonEmpty(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
