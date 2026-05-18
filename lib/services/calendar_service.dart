import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class CalendarService {
  static const String _calendarId = 'primary';
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  Future<String?> _getAccessToken() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      return null;
    }
  }

  Future<bool> addCareTask({
    required String plantName,
    required String taskType,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return false;

      final event = {
        'summary': '$taskType — $plantName 🌱',
        'description': notes ?? 'Flora plant care reminder',
        'start': {
          'dateTime': dueDate.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        'end': {
          'dateTime': dueDate.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 60},
          ],
        },
        'colorId': '2',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/calendars/$_calendarId/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(event),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<int> syncAllTasks({
    required List<Map<String, dynamic>> tasks,
  }) async {
    int synced = 0;
    for (final task in tasks) {
      final plantName = task['plantName'] as String? ?? 'Plant';
      final taskType = task['taskType'] as String? ?? 'Care';
      final dueDate = task['dueDate'] as DateTime?;
      if (dueDate == null) continue;
      if (dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) continue;

      final added = await addCareTask(
        plantName: plantName,
        taskType: taskType,
        dueDate: dueDate,
        notes: task['notes'] as String?,
      );
      if (added) synced++;
    }
    return synced;
  }
}
