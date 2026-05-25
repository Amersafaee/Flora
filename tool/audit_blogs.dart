// ignore_for_file: avoid_print
// dart run tool/audit_blogs.dart
//
// Audits the Firestore 'blogs' collection via the REST API.
// No Flutter / Firebase SDK — runs in plain Dart VM.
//
// Project:  flora-99ff7
// Rules:    blogs → allow read: if true  (no auth required)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Config — derived from lib/firebase_options.dart + firestore.rules
// ---------------------------------------------------------------------------

const _projectId = 'flora-99ff7';

// Firestore REST base URL for the blogs collection
// blogs has  allow read: if true  in firestore.rules → no API key needed.
const _blogsUrl =
    'https://firestore.googleapis.com/v1/projects/$_projectId'
    '/databases/(default)/documents/blogs?pageSize=300';

// ---------------------------------------------------------------------------
// Unsplash search-term generator
// ---------------------------------------------------------------------------

/// Strips common filler words/phrases and returns a 2-3 word search term
/// suitable for an Unsplash image search.
String _unsplashTerm(String title) {
  var t = title;

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

  t = t.replaceAll(RegExp(r'[?!:,.]$'), '').trim();

  const stopWords = {
    'your', 'my', 'our', 'their', 'its', 'the', 'a', 'an',
    'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
    'from', 'by', 'up', 'as', 'is', 'are', 'was', 'be',
    'this', 'that', 'these', 'those',
  };

  final words =
      t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final meaningful =
      words.where((w) => !stopWords.contains(w.toLowerCase())).toList();

  final selected = meaningful.isNotEmpty
      ? meaningful.take(3).toList()
      : words.take(3).toList();

  return selected.join(' ').toLowerCase();
}

// ---------------------------------------------------------------------------
// Firestore REST helpers
// ---------------------------------------------------------------------------

/// Extracts a plain Dart value from a Firestore REST API field value map.
/// e.g. {"stringValue": "hello"} → "hello"
dynamic _fieldValue(dynamic fieldMap) {
  if (fieldMap == null || fieldMap is! Map) return null;
  final m = fieldMap as Map<String, dynamic>;
  if (m.containsKey('stringValue')) return m['stringValue'];
  if (m.containsKey('integerValue')) return m['integerValue'];
  if (m.containsKey('booleanValue')) return m['booleanValue'];
  if (m.containsKey('nullValue')) return null;
  if (m.containsKey('mapValue')) {
    final inner = (m['mapValue'] as Map?)?['fields'] as Map?;
    return inner;
  }
  if (m.containsKey('arrayValue')) {
    final values = (m['arrayValue'] as Map?)?['values'] as List?;
    return values?.map(_fieldValue).toList();
  }
  return null;
}

/// Flattens the Firestore REST "fields" map into a plain `Map<String, dynamic>`.
Map<String, dynamic> _flattenFields(Map<String, dynamic> fields) {
  return fields
      .map((key, val) => MapEntry(key, _fieldValue(val)));
}

/// Returns [value] if it is a non-empty string, otherwise null.
String? _nonEmpty(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// Extracts the document ID from a Firestore REST document name.
/// "projects/flora-99ff7/databases/(default)/documents/blogs/abc123" → "abc123"
String _docId(String name) => name.split('/').last;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  stdout.writeln('\n🔍  BLOG AUDIT — Flora Firestore (REST API)\n');
  stdout.writeln('Project:    $_projectId');
  stdout.writeln('Collection: blogs');
  stdout.writeln('Auth:       none required (allow read: if true in rules)');
  stdout.writeln('');

  // ── Fetch from Firestore REST API ─────────────────────────────────────────
  stdout.writeln('Fetching blogs collection...');

  final List<Map<String, dynamic>> allDocs = [];
  String? pageToken;

  do {
    final uri = Uri.parse(
      pageToken != null ? '$_blogsUrl&pageToken=$pageToken' : _blogsUrl,
    );

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode == 401 || response.statusCode == 403) {
      stdout.writeln('');
      stdout.writeln('⚠️  AUTHENTICATION REQUIRED');
      stdout.writeln('');
      stdout.writeln(
        'The Firestore REST API returned HTTP ${response.statusCode}.',
      );
      stdout.writeln(
        'Although firestore.rules has  allow read: if true  for blogs,',
      );
      stdout.writeln(
        'this may mean the rules have not been deployed yet, or the project',
      );
      stdout.writeln('has organisation-level access controls.');
      stdout.writeln('');
      stdout.writeln('To audit blogs without running this script:');
      stdout.writeln(
        '  1. Go to https://console.firebase.google.com/project/$_projectId/firestore',
      );
      stdout.writeln('  2. Open the "blogs" collection.');
      stdout.writeln('  3. Check each document for imageUrl / thumbnailUrl / image fields.');
      stdout.writeln('');
      stdout.writeln('Or deploy rules first:  firebase deploy --only firestore:rules');
      exit(1);
    }

    if (response.statusCode != 200) {
      stderr.writeln(
        '❌ Unexpected HTTP ${response.statusCode}: ${response.body}',
      );
      exit(1);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = body['documents'] as List<dynamic>? ?? [];

    for (final doc in documents) {
      final docMap = doc as Map<String, dynamic>;
      final name = docMap['name'] as String? ?? '';
      final fields = docMap['fields'] as Map<String, dynamic>? ?? {};
      final flat = _flattenFields(fields);
      flat['_id'] = _docId(name);
      allDocs.add(flat);
    }

    pageToken = body['nextPageToken'] as String?;
  } while (pageToken != null);

  stdout.writeln('Total documents fetched: ${allDocs.length}\n');

  // ── Partition ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> withImages = [];
  final List<Map<String, dynamic>> withoutImages = [];

  for (final data in allDocs) {
    final title =
        (_nonEmpty(data['title']) ?? _nonEmpty(data['name']) ?? '(no title)');
    final id = data['_id'] as String;

    final imageUrl = _nonEmpty(data['imageUrl'])
        ?? _nonEmpty(data['thumbnailUrl'])
        ?? _nonEmpty(data['image']);

    if (imageUrl != null) {
      withImages.add({'id': id, 'title': title, 'imageUrl': imageUrl});
    } else {
      withoutImages
          .add({'id': id, 'title': title, 'unsplash': _unsplashTerm(title)});
    }
  }

  // ── Detect duplicate imageUrls ────────────────────────────────────────────
  // Group withImages entries by their imageUrl value.
  final Map<String, List<Map<String, dynamic>>> urlGroups = {};
  for (final b in withImages) {
    final url = b['imageUrl'] as String;
    urlGroups.putIfAbsent(url, () => []).add(b);
  }
  // Keep only groups where more than one blog shares the same URL.
  final duplicateGroups = urlGroups.entries
      .where((e) => e.value.length > 1)
      .toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final duplicateCount = duplicateGroups.fold<int>(
      0, (sum, e) => sum + e.value.length);

  // ── Section 1: blogs WITH images ─────────────────────────────────────────
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');
  stdout.writeln(
      '  BLOGS WITH IMAGES (keep as-is): ${withImages.length}');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');

  if (withImages.isEmpty) {
    stdout.writeln('  (none)');
  } else {
    for (final b in withImages) {
      // Flag duplicates inline with a ⚠️ marker
      final isDup = urlGroups[b['imageUrl']]!.length > 1;
      stdout.writeln('  ${isDup ? '⚠️ ' : '✅'} ${b['title']}');
      stdout.writeln('     imageUrl: ${b['imageUrl']}');
    }
  }

  // ── Section 1b: DUPLICATE images ─────────────────────────────────────────
  stdout.writeln('');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');
  stdout.writeln(
      '  DUPLICATE IMAGE URLs: ${duplicateGroups.length} URLs shared by $duplicateCount blogs');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');

  if (duplicateGroups.isEmpty) {
    stdout.writeln('  (none — all image URLs are unique 🎉)');
  } else {
    for (final entry in duplicateGroups) {
      stdout.writeln('  🔁 Shared by ${entry.value.length} blogs:');
      stdout.writeln('     url: ${entry.key}');
      for (final b in entry.value) {
        stdout.writeln('       • ${b['title']}  (id: ${b['id']})');
      }
    }
  }

  // ── Section 2: blogs WITHOUT images ──────────────────────────────────────
  stdout.writeln('');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');
  stdout.writeln(
      '  BLOGS WITHOUT IMAGES (need images): ${withoutImages.length}');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');

  if (withoutImages.isEmpty) {
    stdout.writeln('  (none — all blogs have images 🎉)');
  } else {
    for (final b in withoutImages) {
      stdout.writeln('  ❌ ${b['title']}');
      stdout.writeln('     id:       ${b['id']}');
      stdout.writeln('     unsplash: ${b['unsplash']}');
    }
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  stdout.writeln('');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');
  stdout.writeln('  SUMMARY');
  stdout.writeln('  Total blogs:          ${allDocs.length}');
  stdout.writeln('  With images:          ${withImages.length}');
  stdout.writeln('  Without images:       ${withoutImages.length}');
  stdout.writeln('  Duplicate URLs:       ${duplicateGroups.length} URL(s) shared by $duplicateCount blog(s)');
  stdout.writeln(
      '═══════════════════════════════════════════════════════════');

  // ── Copy-this-list block ──────────────────────────────────────────────────
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
