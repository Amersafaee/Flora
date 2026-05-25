// ignore_for_file: avoid_print
// dart run tool/update_blog_image_paths.dart
//
// PATCHes the localImagePath field of each blog document in Firestore
// via the REST API (no Flutter / Firebase SDK — runs in plain Dart VM).
//
// Project:  flora-99ff7
// Auth:     none required for writes if rules allow write: if true,
//           otherwise run: gcloud auth print-identity-token  and set
//           the FIREBASE_TOKEN env-var before running.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const _projectId = 'flora-99ff7';

/// PATCH endpoint — updateMask ensures only localImagePath is touched.
String _patchUrl(String docId) =>
    'https://firestore.googleapis.com/v1/projects/$_projectId'
    '/databases/(default)/documents/blogs/$docId'
    '?updateMask.fieldPaths=localImagePath';

// ---------------------------------------------------------------------------
// Mapping: Firestore document ID → local asset path
// ---------------------------------------------------------------------------

const Map<String, String> _blogImageMap = {
  'beginner_guide_to_propagation':
      'assets/blog_images/beginner_guide_to_propagation.jpg',
  'best_soil_mixes_for_indoor_plants':
      'assets/blog_images/best_soil_mixes_for_indoor_plants.jpg',
  'bottom-watering-african-violets-peperomias':
      'assets/blog_images/bottom-watering-african-violets-peperomias.jpg',
  'bright-indirect-light-reality':
      'assets/blog_images/bright-indirect-light-reality.jpg',
  'choosing-pot-material': 'assets/blog_images/choosing-pot-material.jpg',
  'common_watering_mistakes':
      'assets/blog_images/common_watering_mistakes.jpg',
  'deep-watering-large-plants':
      'assets/blog_images/deep-watering-large-plants.jpg',
  'diagnosing_yellow_leaves':
      'assets/blog_images/diagnosing_yellow_leaves.jpg',
  'drainage-holes-alternatives':
      'assets/blog_images/drainage-holes-alternatives.jpg',
  'east-vs-west-windows': 'assets/blog_images/east-vs-west-windows.jpg',
  'edema-peperomia-pilea': 'assets/blog_images/edema-peperomia-pilea.jpg',
  'finger-test-proper-technique':
      'assets/blog_images/finger-test-proper-technique.jpg',
  'grow-light-distance-duration':
      'assets/blog_images/grow-light-distance-duration.jpg',
  'how_humidity_affects_tropical_plants':
      'assets/blog_images/how_humidity_affects_tropical_plants.jpg',
  'how_to_repot_without_stress':
      'assets/blog_images/how_to_repot_without_stress.jpg',
  'humidity-vs-watering': 'assets/blog_images/humidity-vs-watering.jpg',
  'hydrophobic-soil-fix': 'assets/blog_images/hydrophobic-soil-fix.jpg',
  'light-and-leaf-orientation':
      'assets/blog_images/light-and-leaf-orientation.jpg',
  'light-for-flowering-hoya-orchid':
      'assets/blog_images/light-for-flowering-hoya-orchid.jpg',
  'light-for-propagations': 'assets/blog_images/light-for-propagations.jpg',
  'low-light-myths': 'assets/blog_images/low-light-myths.jpg',
  'lux-meter-light-measurement':
      'assets/blog_images/lux-meter-light-measurement.jpg',
  'moisture-meter-mistakes': 'assets/blog_images/moisture-meter-mistakes.jpg',
  'natural_pest_control_for_houseplants':
      'assets/blog_images/natural_pest_control_for_houseplants.jpg',
  'orchid-ice-cube-myth': 'assets/blog_images/orchid-ice-cube-myth.jpg',
  'potting-mix-amendments': 'assets/blog_images/potting-mix-amendments.jpg',
  'rainwater-vs-tap-water': 'assets/blog_images/rainwater-vs-tap-water.jpg',
  'reading_your_plant_signs':
      'assets/blog_images/reading_your_plant_signs.jpg',
  'repotting-rootbound-techniques':
      'assets/blog_images/repotting-rootbound-techniques.jpg',
  'root-rot-treatment-after':
      'assets/blog_images/root-rot-treatment-after.jpg',
  'rotating-plants-how-often':
      'assets/blog_images/rotating-plants-how-often.jpg',
  'saucers-and-salt-buildup':
      'assets/blog_images/saucers-and-salt-buildup.jpg',
  'seasonal-watering-adjustments':
      'assets/blog_images/seasonal-watering-adjustments.jpg',
  'self-watering-pots-pros-cons':
      'assets/blog_images/self-watering-pots-pros-cons.jpg',
  'shadow-test-room-light': 'assets/blog_images/shadow-test-room-light.jpg',
  'sheer-curtains-effectively':
      'assets/blog_images/sheer-curtains-effectively.jpg',
  'soil-compaction-causes-fixes':
      'assets/blog_images/soil-compaction-causes-fixes.jpg',
  'south-vs-north-windows': 'assets/blog_images/south-vs-north-windows.jpg',
  'succulent-overwatering-vs-underwatering':
      'assets/blog_images/succulent-overwatering-vs-underwatering.jpg',
  'sunburn-vs-acclimation': 'assets/blog_images/sunburn-vs-acclimation.jpg',
  'supplemental-winter-lighting':
      'assets/blog_images/supplemental-winter-lighting.jpg',
  'understanding_light_levels':
      'assets/blog_images/understanding_light_levels.jpg',
  'vacation-watering-solutions':
      'assets/blog_images/vacation-watering-solutions.jpg',
  'variegation-and-light': 'assets/blog_images/variegation-and-light.jpg',
  'watering-carnivorous-plants':
      'assets/blog_images/watering-carnivorous-plants.jpg',
  'watering-ferns-consistently':
      'assets/blog_images/watering-ferns-consistently.jpg',
  'watering-hanging-plants': 'assets/blog_images/watering-hanging-plants.jpg',
  'watering-newly-repotted-plants':
      'assets/blog_images/watering-newly-repotted-plants.jpg',
  'watering-propagated-cuttings':
      'assets/blog_images/watering-propagated-cuttings.jpg',
  'winter_plant_care_guide': 'assets/blog_images/winter_plant_care_guide.jpg',
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  stdout.writeln('\n📝  UPDATE BLOG localImagePath — Flora Firestore (REST API)\n');
  stdout.writeln('Project:    $_projectId');
  stdout.writeln('Documents:  ${_blogImageMap.length}');
  stdout.writeln('Field:      localImagePath (PATCH with updateMask)\n');

  // Optional bearer token (for when Firestore write rules require auth)
  final token = Platform.environment['FIREBASE_TOKEN'];
  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  int successCount = 0;
  int failCount = 0;
  final List<String> failures = [];

  for (final entry in _blogImageMap.entries) {
    final docId = entry.key;
    final assetPath = entry.value;

    final body = jsonEncode({
      'fields': {
        'localImagePath': {'stringValue': assetPath},
      },
    });

    final url = _patchUrl(docId);

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        stdout.writeln('  ✅  $docId');
        stdout.writeln('       → $assetPath');
        successCount++;
      } else {
        stdout.writeln('  ❌  $docId  (HTTP ${response.statusCode})');
        stdout.writeln('       body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
        failCount++;
        failures.add(docId);
      }
    } catch (e) {
      stdout.writeln('  ❌  $docId  (exception: $e)');
      failCount++;
      failures.add(docId);
    }

    // Small delay to avoid hitting Firestore rate limits
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════════');
  stdout.writeln('  SUMMARY');
  stdout.writeln('  Total attempted: ${_blogImageMap.length}');
  stdout.writeln('  Succeeded:       $successCount');
  stdout.writeln('  Failed:          $failCount');
  if (failures.isNotEmpty) {
    stdout.writeln('  Failed IDs:');
    for (final id in failures) {
      stdout.writeln('    • $id');
    }
    stdout.writeln('');
    stdout.writeln('  If you see 401/403 errors, set FIREBASE_TOKEN:');
    stdout.writeln('    \$env:FIREBASE_TOKEN = (gcloud auth print-identity-token)');
    stdout.writeln('  Then re-run:');
    stdout.writeln('    dart run tool/update_blog_image_paths.dart');
  }
  stdout.writeln('═══════════════════════════════════════════════════════════\n');

  exit(failCount > 0 ? 1 : 0);
}
