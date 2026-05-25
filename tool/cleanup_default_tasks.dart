/// One-time Firestore cleanup: removes any task document whose title/taskType
/// contains "inception", "sample", or "default" from ALL users' task
/// subcollections.
///
/// Run with:
///   dart run tool/cleanup_default_tasks.dart
///
/// This script uses the Firebase Admin SDK via the REST API approach,
/// so it requires a service account key.  Place your service account JSON
/// at the path referenced by [serviceAccountPath] before running.
///
/// NOTE: This is a destructive, one-time operation.  Review the printed list
/// of documents before confirming deletion.
library;

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Absolute (or workspace-relative) path to your Firebase service account key.
const serviceAccountPath = 'tool/service_account_key.json';

/// Firestore base URL for your project.  Replace `PROJECT_ID` with your
/// actual Firebase project ID.
const projectId = 'YOUR_PROJECT_ID';  // ← set this before running

/// Lower-case substrings that identify "default" tasks that should never
/// have been created.
const List<String> _bannedTitleFragments = [
  'inception',
  'sample',
  'default',
];

// ---------------------------------------------------------------------------
// Script entry point
// ---------------------------------------------------------------------------

Future<void> main() async {
  print('━━━ cleanup_default_tasks.dart ━━━');
  print('Project : $projectId');
  print('Banned fragments: ${_bannedTitleFragments.join(", ")}');
  print('');

  if (projectId == 'YOUR_PROJECT_ID') {
    print('ERROR: Set projectId at the top of this file before running.');
    exit(1);
  }

  if (!File(serviceAccountPath).existsSync()) {
    print('ERROR: Service account key not found at: $serviceAccountPath');
    print('Download it from Firebase Console → Project Settings → Service Accounts.');
    exit(1);
  }

  // ── Step 1: List all user documents ──────────────────────────────────────
  final accessToken = await _getAccessToken();
  final users = await _listDocuments(accessToken, 'users');
  print('Found ${users.length} user(s).');

  int totalDeleted = 0;

  for (final userPath in users) {
    final uid = userPath.split('/').last;
    final tasks = await _listDocuments(accessToken, 'users/$uid/tasks');
    if (tasks.isEmpty) continue;

    for (final taskPath in tasks) {
      final taskData = await _getDocument(accessToken, taskPath);
      final fields = taskData['fields'] as Map<String, dynamic>? ?? {};

      // Check both 'title' and 'taskType' fields (the app uses taskType).
      final title = _extractString(fields, 'title');
      final taskType = _extractString(fields, 'taskType');
      final plantName = _extractString(fields, 'plantName');

      final combined = '${title.toLowerCase()} ${taskType.toLowerCase()} ${plantName.toLowerCase()}';

      final isBanned = _bannedTitleFragments.any((f) => combined.contains(f));
      if (!isBanned) continue;

      print('  → Deleting [$uid] task: title="$title" taskType="$taskType" plantName="$plantName"');
      await _deleteDocument(accessToken, taskPath);
      totalDeleted++;
    }
  }

  print('');
  print('Done.  Deleted $totalDeleted document(s).');
}

// ---------------------------------------------------------------------------
// Firestore REST helpers
// ---------------------------------------------------------------------------

/// Returns a list of document resource names under [collectionPath].
Future<List<String>> _listDocuments(
    String accessToken, String collectionPath) async {
  final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionPath');
  final response = await HttpClient().getUrl(uri).then((req) {
    req.headers.set('Authorization', 'Bearer $accessToken');
    return req.close();
  });

  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    print('  [WARN] listDocuments($collectionPath) → ${response.statusCode}: $body');
    return [];
  }

  final json = jsonDecode(body) as Map<String, dynamic>;
  final docs = (json['documents'] as List<dynamic>?) ?? [];
  return docs
      .map((d) => (d as Map<String, dynamic>)['name'] as String)
      // Strip the leading "projects/.../documents/" prefix to get the relative
      // Firestore path, but we keep the full name for delete/get calls.
      .toList();
}

/// Fetches a single Firestore document by its full resource [name].
Future<Map<String, dynamic>> _getDocument(
    String accessToken, String name) async {
  final uri = Uri.parse('https://firestore.googleapis.com/v1/$name');
  final response = await HttpClient().getUrl(uri).then((req) {
    req.headers.set('Authorization', 'Bearer $accessToken');
    return req.close();
  });
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) return {};
  return jsonDecode(body) as Map<String, dynamic>;
}

/// Deletes a Firestore document by its full resource [name].
Future<void> _deleteDocument(String accessToken, String name) async {
  final uri = Uri.parse('https://firestore.googleapis.com/v1/$name');
  final request = await HttpClient().deleteUrl(uri);
  request.headers.set('Authorization', 'Bearer $accessToken');
  final response = await request.close();
  if (response.statusCode != 200 && response.statusCode != 204) {
    final body = await response.transform(utf8.decoder).join();
    print('  [ERROR] deleteDocument($name) → ${response.statusCode}: $body');
  }
}

/// Extracts a string value from a Firestore field map entry.
String _extractString(Map<String, dynamic> fields, String key) {
  final field = fields[key];
  if (field == null) return '';
  if (field is Map) return (field['stringValue'] as String?) ?? '';
  return '';
}

/// Obtains a short-lived OAuth2 access token from the service account JSON.
///
/// Uses the Dart [jwt] approach: we sign a JWT assertion manually so this
/// script has zero external dependencies beyond what ships with Dart.
Future<String> _getAccessToken() async {
  final keyJson =
      jsonDecode(File(serviceAccountPath).readAsStringSync()) as Map<String, dynamic>;

  final clientEmail = keyJson['client_email'] as String;
  final privateKeyPem = keyJson['private_key'] as String;
  final tokenUri = keyJson['token_uri'] as String? ??
      'https://oauth2.googleapis.com/token';

  // Build the JWT header + claims.
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64UrlEncode(
      utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})));
  final claims = base64UrlEncode(utf8.encode(jsonEncode({
    'iss': clientEmail,
    'scope': 'https://www.googleapis.com/auth/datastore',
    'aud': tokenUri,
    'iat': now,
    'exp': now + 3600,
  })));

  // NOTE: Signing requires dart:io + dart:ffi or a crypto package.
  // For simplicity we shell out to openssl which is available on most systems.
  final jwtUnsigned = '$header.$claims';
  final tmpInput = File('${Directory.systemTemp.path}/jwt_input.txt')
    ..writeAsStringSync(jwtUnsigned);
  final tmpKey = File('${Directory.systemTemp.path}/sa_key.pem')
    ..writeAsStringSync(privateKeyPem);

  final sigProcess = await Process.run('openssl', [
    'dgst', '-sha256', '-sign', tmpKey.path, tmpInput.path,
  ], stdoutEncoding: null);

  if (sigProcess.exitCode != 0) {
    throw Exception('openssl signing failed: ${sigProcess.stderr}');
  }

  final sigBytes = sigProcess.stdout as List<int>;
  final sig = base64UrlEncode(sigBytes).replaceAll('=', '');
  final jwt = '$jwtUnsigned.$sig';

  // Exchange JWT for an access token.
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse(tokenUri));
  req.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
  req.write(
      'grant_type=${Uri.encodeComponent("urn:ietf:params:oauth:grant-type:jwt-bearer")}'
      '&assertion=${Uri.encodeComponent(jwt)}');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final tokenJson = jsonDecode(body) as Map<String, dynamic>;

  if (tokenJson['access_token'] == null) {
    throw Exception('Failed to get access token: $body');
  }
  return tokenJson['access_token'] as String;
}
