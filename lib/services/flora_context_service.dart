import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Builds a rich, personalised context document about the user and their
/// plants. The resulting String is injected into the Gemini system prompt so
/// Flora feels like she genuinely knows the user's collection.
class FloraContextService {
  final FirebaseFirestore _db;
  FloraContextService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // ── In-memory cache ───────────────────────────────────────────────────────
  // Key: "$uid|$conversationId", Value: (timestamp, contextString)
  static final Map<String, (DateTime, String)> _cache = {};
  static const _cacheTtl = Duration(seconds: 60);

  /// Fetches all relevant user data and returns a structured plain-English
  /// summary ready to be embedded in a system prompt.
  ///
  /// Per-plant growth + task queries run in parallel via [Future.wait].
  /// Results are cached for [_cacheTtl] per uid+conversationId pair.
  Future<String> buildContext(String uid, String conversationId) async {
    // ── Cache check ──────────────────────────────────────────────────────────
    final cacheKey = '$uid|$conversationId';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < _cacheTtl) {
      return cached.$2;
    }

    try {
      final results = await Future.wait([
        _fetchProfile(uid),
        _fetchPlants(uid),
        _fetchClimateReadings(uid),
        _fetchRecentChatMessages(uid, conversationId),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final plants = results[1] as List<Map<String, dynamic>>;
      final climateReadings = results[2] as List<Map<String, dynamic>>;
      final chatMessages = results[3] as List<Map<String, dynamic>>;

      final perPlantFutures = plants.map((plant) async {
        final plantId = plant['id'] as String? ?? '';
        final name = (plant['name'] as String?)?.trim() ?? 'Unknown Plant';

        if (plantId.isEmpty) return <String, dynamic>{'plant': plant};

        final pResults = await Future.wait([
          _fetchLastGrowthEntries(uid, plantId),
          _fetchPlantTaskSummary(uid, name),
        ]);

        return <String, dynamic>{
          'plant': plant,
          'growth': pResults[0] as List<Map<String, dynamic>>,
          'tasks': pResults[1] as Map<String, int>,
        };
      });

      final perPlantData = await Future.wait(perPlantFutures);

      var result = generateContextString(
        profile, plants, perPlantData, climateReadings, chatMessages
      );

      // ── Store in cache ───────────────────────────────────────────────────
      _cache[cacheKey] = (DateTime.now(), result);

      return result;
    } catch (e) {
      return 'Context unavailable at this time.';
    }
  }

  @visibleForTesting
  String generateContextString(
    Map<String, dynamic>? profile,
    List<Map<String, dynamic>> plants,
    List<dynamic> perPlantData,
    List<Map<String, dynamic>> climateReadings,
    List<Map<String, dynamic>> chatMessages,
  ) {
      // ── User greeting line ────────────────────────────────────────────────

      // ── User greeting line ────────────────────────────────────────────────
      final displayName =
          (profile?['fullName'] as String?)?.trim().isNotEmpty == true
              ? profile!['fullName'] as String
              : (profile?['displayName'] as String?)?.trim().isNotEmpty == true
                  ? profile!['displayName'] as String
                  : 'the user';

      final buffer = StringBuffer();
      buffer.writeln('The user\'s name is $displayName.');
      buffer.writeln(
          'They have ${plants.length} plant${plants.length == 1 ? '' : 's'} in their collection.');
      buffer.writeln();


      for (final data in perPlantData) {
        final plant = data['plant'] as Map<String, dynamic>;
        final growthEntries =
            data['growth'] as List<Map<String, dynamic>>? ?? [];
        final taskSummary =
            data['tasks'] as Map<String, int>? ?? {'completed': 0, 'skipped': 0};

        final name = (plant['name'] as String?)?.trim() ?? 'Unknown Plant';
        final commonName = (plant['commonName'] as String?)?.trim() ?? '';
        final category = (plant['category'] as String?)?.trim() ?? 'Unknown';
        final healthStatus =
            (plant['healthStatus'] as String?)?.trim() ?? 'Unknown';
        final zone = (plant['zone'] as String?)?.trim() ?? '';

        DateTime? dateAdded;
        final rawDate = plant['dateAdded'];
        if (rawDate is Timestamp) {
          dateAdded = rawDate.toDate();
        } else if (rawDate is DateTime) {
          dateAdded = rawDate;
        }
        final dateAddedStr = dateAdded != null
            ? DateFormat('MMMM d, yyyy').format(dateAdded)
            : 'an unknown date';

        final hasDistinctNickname =
            commonName.isNotEmpty &&
            commonName.toLowerCase() != name.toLowerCase();

        buffer.write('$name is a $category plant');
        if (hasDistinctNickname) buffer.write(' (also known as $commonName)');
        if (zone.isNotEmpty) buffer.write(', kept in the $zone zone');
        buffer.writeln('.');
        buffer.writeln(
            'It has been in the collection since $dateAddedStr. Current health status is $healthStatus.');

        if (growthEntries.isNotEmpty) {
          final lastEntry = growthEntries.first;
          final entryNotes =
              (lastEntry['notes'] as String?)?.trim() ?? 'no notes recorded';
          DateTime? entryDate;
          final rawTs = lastEntry['timestamp'];
          if (rawTs is Timestamp) entryDate = rawTs.toDate();
          final entryDateStr = entryDate != null
              ? DateFormat('MMMM d, yyyy').format(entryDate)
              : 'an unknown date';
          buffer.writeln(
              'The last growth journal entry was on $entryDateStr and noted: "$entryNotes".');
        }

        buffer.writeln(
            'In the last 30 days they completed ${taskSummary['completed']} care task${taskSummary['completed'] == 1 ? '' : 's'} '
            'and skipped ${taskSummary['skipped']} care task${taskSummary['skipped'] == 1 ? '' : 's'} for this plant.');

        if (healthStatus.isNotEmpty &&
            healthStatus.toLowerCase() != 'healthy' &&
            healthStatus.toLowerCase() != 'good') {
          buffer.writeln(
              'This plant has an active health concern: $healthStatus.');
        }

        buffer.writeln();
      }

      // ── Climate summary ───────────────────────────────────────────────────
      if (climateReadings.isNotEmpty) {
        final tempReadings = climateReadings
            .where((r) => r['type'] == 'temperature')
            .map((r) => (r['value'] as num).toDouble())
            .toList();
        final humReadings = climateReadings
            .where((r) => r['type'] == 'humidity')
            .map((r) => (r['value'] as num).toDouble())
            .toList();

        buffer.write('Recent environment: ');
        if (tempReadings.isNotEmpty) {
          final avgTemp =
              tempReadings.reduce((a, b) => a + b) / tempReadings.length;
          buffer.write('average temperature ${avgTemp.toStringAsFixed(1)}°C');
        }
        if (humReadings.isNotEmpty) {
          final avgHum =
              humReadings.reduce((a, b) => a + b) / humReadings.length;
          if (tempReadings.isNotEmpty) buffer.write(', ');
          buffer.write('average humidity ${avgHum.toStringAsFixed(1)}%');
        }
        buffer.writeln('.');
        buffer.writeln();
      }

      // ── Recent conversation context ───────────────────────────────────────
      if (chatMessages.isNotEmpty) {
        final topics = chatMessages
            .where((m) => (m['text'] as String?)?.isNotEmpty == true)
            .map((m) {
          final role = m['role'] == 'user' ? 'User' : 'Flora';
          final text = (m['text'] as String).trim();
          final snippet = text.length > 120 ? '${text.substring(0, 117)}…' : text;
          return '$role: "$snippet"';
        }).join(' | ');

        buffer.writeln('Recent conversation context (last messages): $topics');
        buffer.writeln();
      }

      var result = buffer.toString().trim();
      if (result.length > 1500) {
        result = '${result.substring(0, 1500)}... [context truncated for performance]';
      }

      return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> _fetchPlants(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('plants')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  /// Fetches only the single most recent growth entry — enough context for
  /// Flora without the overhead of fetching 5 entries per plant.
  Future<List<Map<String, dynamic>>> _fetchLastGrowthEntries(
      String uid, String plantId) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .collection('growth')
        .orderBy('timestamp', descending: true)
        .limit(1) // reduced from 5
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Returns completed + skipped counts for a specific plant name in the
  /// last 30 days from the top-level tasks collection.
  Future<Map<String, int>> _fetchPlantTaskSummary(
      String uid, String plantName) async {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 14)));

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('plantName', isEqualTo: plantName)
        .where('dueDate', isGreaterThanOrEqualTo: since)
        .get();

    int completed = 0;
    int skipped = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isCompleted'] == true) {
        completed++;
      } else {
        final dueDate = data['dueDate'];
        DateTime? due;
        if (dueDate is Timestamp) due = dueDate.toDate();
        if (due != null && due.isBefore(DateTime.now())) {
          skipped++;
        }
      }
    }
    return {'completed': completed, 'skipped': skipped};
  }

  Future<List<Map<String, dynamic>>> _fetchClimateReadings(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('zones')
        .doc('main_zone')
        .collection('readings')
        .orderBy('timestamp', descending: true)
        .limit(3) // reduced from 7
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRecentChatMessages(
      String uid, String conversationId) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('flora_chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(5) // reduced from 10
        .get();
    // Return in chronological order so the summary reads naturally
    final docs = snap.docs.map((d) => d.data()).toList();
    return docs.reversed.toList();
  }
}
