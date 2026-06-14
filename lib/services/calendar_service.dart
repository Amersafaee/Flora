import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static String? _calendarId;
  static bool _tzInitialized = false;

  static Future<void> _init() async {
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      _tzInitialized = true;
    }
    if (_calendarId != null) return;

    final permResult = await _plugin.requestPermissions();
    if (permResult.data != true) return;

    final calendarsResult = await _plugin.retrieveCalendars();
    final calendars = calendarsResult.data ?? [];

    // Prefer a writable, non-read-only calendar
    final writable = calendars.where((c) => c.isReadOnly == false).toList();
    if (writable.isEmpty) return;

    // Prefer the default/local calendar, otherwise take the first writable one
    _calendarId = (writable.firstWhere(
      (c) => c.isDefault == true,
      orElse: () => writable.first,
    )).id;
  }

  // Returns "calendarId::eventId" or null on failure
  static Future<String?> createEvent({
    required String title,
    required DateTime date,
    String? description,
  }) async {
    try {
      await _init();
      if (_calendarId == null) return null;

      final local = tz.local;
      final start = tz.TZDateTime(
        local, date.year, date.month, date.day, 9, 0,
      );
      final end = start.add(const Duration(hours: 1));

      final event = Event(
        _calendarId!,
        title: title,
        description: description,
        start: start,
        end: end,
        reminders: [Reminder(minutes: 10)],
      );

      final result = await _plugin.createOrUpdateEvent(event);
      if (result?.data == null) return null;
      return '$_calendarId::${result!.data}';
    } catch (_) {
      return null;
    }
  }

  // Pass the combined "calendarId::eventId" string returned by createEvent
  static Future<void> deleteEvent(String? combinedId) async {
    if (combinedId == null || !combinedId.contains('::')) return;
    try {
      final parts = combinedId.split('::');
      final calId = parts[0];
      final eventId = parts[1];
      await _plugin.deleteEvent(calId, eventId);
    } catch (_) {}
  }
}
