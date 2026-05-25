// ignore_for_file: avoid_print
// dart run tool/upload_blog_images.dart
//
// 1. Gets a Firebase auth token via the Firebase Auth REST API (anonymous sign-in)
//    using the Android API key from .env.
// 2. Uploads every .jpg in assets/blog_images/ to Firebase Storage REST API.
// 3. PATCHes the matching Firestore blog document's imageUrl field.
//
// Project : flora-99ff7
// Bucket  : flora-99ff7.firebasestorage.app

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const _projectId = 'flora-99ff7';
const _bucket = 'flora-99ff7.firebasestorage.app';
// Android API key — read from .env (same key used by the app)
const _apiKey = 'AIzaSyDC94PXNxLYGEY9vpqSs-QHXFfN3cJkmTY';
const _assetDir = 'assets/blog_images';

// ---------------------------------------------------------------------------
// Mapping: Firestore document ID → local filename stem
// (must match what update_blog_image_paths.dart uses)
// ---------------------------------------------------------------------------

const Map<String, String> _docToFilename = {
  'beginner_guide_to_propagation': 'beginner_guide_to_propagation.jpg',
  'best_soil_mixes_for_indoor_plants': 'best_soil_mixes_for_indoor_plants.jpg',
  'bottom-watering-african-violets-peperomias':
      'bottom-watering-african-violets-peperomias.jpg',
  'bright-indirect-light-reality': 'bright-indirect-light-reality.jpg',
  'choosing-pot-material': 'choosing-pot-material.jpg',
  'common_watering_mistakes': 'common_watering_mistakes.jpg',
  'deep-watering-large-plants': 'deep-watering-large-plants.jpg',
  'diagnosing_yellow_leaves': 'diagnosing_yellow_leaves.jpg',
  'drainage-holes-alternatives': 'drainage-holes-alternatives.jpg',
  'east-vs-west-windows': 'east-vs-west-windows.jpg',
  'edema-peperomia-pilea': 'edema-peperomia-pilea.jpg',
  'finger-test-proper-technique': 'finger-test-proper-technique.jpg',
  'grow-light-distance-duration': 'grow-light-distance-duration.jpg',
  'how_humidity_affects_tropical_plants':
      'how_humidity_affects_tropical_plants.jpg',
  'how_to_repot_without_stress': 'how_to_repot_without_stress.jpg',
  'humidity-vs-watering': 'humidity-vs-watering.jpg',
  'hydrophobic-soil-fix': 'hydrophobic-soil-fix.jpg',
  'light-and-leaf-orientation': 'light-and-leaf-orientation.jpg',
  'light-for-flowering-hoya-orchid': 'light-for-flowering-hoya-orchid.jpg',
  'light-for-propagations': 'light-for-propagations.jpg',
  'low-light-myths': 'low-light-myths.jpg',
  'lux-meter-light-measurement': 'lux-meter-light-measurement.jpg',
  'moisture-meter-mistakes': 'moisture-meter-mistakes.jpg',
  'natural_pest_control_for_houseplants':
      'natural_pest_control_for_houseplants.jpg',
  'orchid-ice-cube-myth': 'orchid-ice-cube-myth.jpg',
  'potting-mix-amendments': 'potting-mix-amendments.jpg',
  'rainwater-vs-tap-water': 'rainwater-vs-tap-water.jpg',
  'reading_your_plant_signs': 'reading_your_plant_signs.jpg',
  'repotting-rootbound-techniques': 'repotting-rootbound-techniques.jpg',
  'root-rot-treatment-after': 'root-rot-treatment-after.jpg',
  'rotating-plants-how-often': 'rotating-plants-how-often.jpg',
  'saucers-and-salt-buildup': 'saucers-and-salt-buildup.jpg',
  'seasonal-watering-adjustments': 'seasonal-watering-adjustments.jpg',
  'self-watering-pots-pros-cons': 'self-watering-pots-pros-cons.jpg',
  'shadow-test-room-light': 'shadow-test-room-light.jpg',
  'sheer-curtains-effectively': 'sheer-curtains-effectively.jpg',
  'soil-compaction-causes-fixes': 'soil-compaction-causes-fixes.jpg',
  'south-vs-north-windows': 'south-vs-north-windows.jpg',
  'succulent-overwatering-vs-underwatering':
      'succulent-overwatering-vs-underwatering.jpg',
  'sunburn-vs-acclimation': 'sunburn-vs-acclimation.jpg',
  'supplemental-winter-lighting': 'supplemental-winter-lighting.jpg',
  'understanding_light_levels': 'understanding_light_levels.jpg',
  'vacation-watering-solutions': 'vacation-watering-solutions.jpg',
  'variegation-and-light': 'variegation-and-light.jpg',
  'watering-carnivorous-plants': 'watering-carnivorous-plants.jpg',
  'watering-ferns-consistently': 'watering-ferns-consistently.jpg',
  'watering-hanging-plants': 'watering-hanging-plants.jpg',
  'watering-newly-repotted-plants': 'watering-newly-repotted-plants.jpg',
  'watering-propagated-cuttings': 'watering-propagated-cuttings.jpg',
  'winter_plant_care_guide': 'winter_plant_care_guide.jpg',
};

// ---------------------------------------------------------------------------
// Auth: get an anonymous Firebase ID token via REST API
// ---------------------------------------------------------------------------

Future<String> _getFirebaseToken() async {
  // First try FIREBASE_TOKEN env var (set via firebase login:ci or gcloud)
  final envToken = Platform.environment['FIREBASE_TOKEN'];
  if (envToken != null && envToken.isNotEmpty) {
    stdout.writeln('  Using FIREBASE_TOKEN from environment.\n');
    return envToken;
  }

  stdout.writeln('  Signing in anonymously via Firebase Auth REST API...');
  final url = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
  );
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'returnSecureToken': true}),
  );
  if (response.statusCode != 200) {
    stderr.writeln('  Failed to get auth token: ${response.body}');
    exit(1);
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final token = body['idToken'] as String?;
  if (token == null || token.isEmpty) {
    stderr.writeln('  idToken missing from auth response.');
    exit(1);
  }
  stdout.writeln('  Anonymous auth token obtained.\n');
  return token;
}

// ---------------------------------------------------------------------------
// Storage: upload a file, return the public download URL
// ---------------------------------------------------------------------------

Future<String?> _uploadToStorage(
  String filePath,
  String storageName,
  String token,
) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    stdout.writeln('    ⚠️  File not found: $filePath — skipping');
    return null;
  }
  final bytes = await file.readAsBytes();

  // URL-encode the storage path for the object name query param
  final encodedName = Uri.encodeComponent('blog_images/$storageName');
  final uploadUrl = Uri.parse(
    'https://firebasestorage.googleapis.com/v0/b/$_bucket/o?name=$encodedName',
  );

  final response = await http.post(
    uploadUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'image/jpeg',
      'Content-Length': '${bytes.length}',
    },
    body: bytes,
  );

  if (response.statusCode != 200) {
    stdout.writeln(
      '    ❌  Upload failed (HTTP ${response.statusCode}): '
      '${response.body.substring(0, response.body.length.clamp(0, 200))}',
    );
    return null;
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final downloadToken = json['downloadTokens'] as String?;
  if (downloadToken == null) {
    stdout.writeln('    ❌  No downloadTokens in upload response.');
    return null;
  }

  final encodedPath = Uri.encodeComponent('blog_images/$storageName');
  return 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/'
      '$encodedPath?alt=media&token=$downloadToken';
}

// ---------------------------------------------------------------------------
// Firestore: PATCH imageUrl field on a blog document
// ---------------------------------------------------------------------------

String _patchUrl(String docId) =>
    'https://firestore.googleapis.com/v1/projects/$_projectId'
    '/databases/(default)/documents/blogs/$docId'
    '?updateMask.fieldPaths=imageUrl';

Future<bool> _patchImageUrl(
  String docId,
  String imageUrl,
  String token,
) async {
  final body = jsonEncode({
    'fields': {
      'imageUrl': {'stringValue': imageUrl},
    },
  });

  final response = await http.patch(
    Uri.parse(_patchUrl(docId)),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: body,
  );

  return response.statusCode == 200;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  stdout.writeln('\n🌿  UPLOAD BLOG IMAGES — Flora Firebase Storage\n');
  stdout.writeln('  Project : $_projectId');
  stdout.writeln('  Bucket  : $_bucket');
  stdout.writeln('  Images  : $_assetDir/');
  stdout.writeln('  Docs    : ${_docToFilename.length}\n');

  // Step 1: Auth
  stdout.writeln('Step 1/3  Getting auth token...');
  final token = await _getFirebaseToken();

  // Step 2 + 3: Upload + Patch
  stdout.writeln('Step 2/3  Uploading images & updating Firestore...\n');

  int successCount = 0;
  int failCount = 0;
  int skipCount = 0;
  int i = 0;
  final List<String> failures = [];

  for (final entry in _docToFilename.entries) {
    i++;
    final docId = entry.key;
    final filename = entry.value;
    final filePath = '$_assetDir/$filename';

    stdout.write('  ($i/${_docToFilename.length})  $filename ... ');

    final downloadUrl = await _uploadToStorage(filePath, filename, token);

    if (downloadUrl == null) {
      stdout.writeln('SKIP (file missing or upload failed)');
      skipCount++;
      failures.add(docId);
      continue;
    }

    stdout.writeln('uploaded');
    stdout.writeln('    → $downloadUrl');

    // Patch Firestore
    final patched = await _patchImageUrl(docId, downloadUrl, token);
    if (patched) {
      stdout.writeln('    ✅  Firestore imageUrl patched for $docId');
      successCount++;
    } else {
      stdout.writeln('    ❌  Firestore PATCH failed for $docId');
      failCount++;
      failures.add(docId);
    }

    // Brief pause to stay within rate limits
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  // Summary
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════════');
  stdout.writeln('  SUMMARY');
  stdout.writeln('  Total:     ${_docToFilename.length}');
  stdout.writeln('  Uploaded + Patched: $successCount');
  stdout.writeln('  Firestore fail:     $failCount');
  stdout.writeln('  Skipped (missing):  $skipCount');
  if (failures.isNotEmpty) {
    stdout.writeln('  Problem IDs:');
    for (final id in failures) {
      stdout.writeln('    • $id');
    }
    stdout.writeln('');
    stdout.writeln('  Tip: if you see 403 errors, set a token manually:');
    stdout.writeln(
      '    \$env:FIREBASE_TOKEN = (firebase login:ci --no-localhost)',
    );
    stdout.writeln('  Then re-run: dart run tool/upload_blog_images.dart');
  }
  stdout.writeln('═══════════════════════════════════════════════════════════\n');

  exit((failCount + (skipCount > 0 ? 1 : 0)) > 0 ? 1 : 0);
}
