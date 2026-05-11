import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _flutterLocalNotificationsPlugin.show(id, title, body, details);
  }

  Future<void> scheduleTaskNotification(
      String taskId, String plantName, String taskType, DateTime dueDate) async {
    
    // Set time to 8:00 AM on the due date
    var scheduledDate = tz.TZDateTime.local(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      8,
      0,
    );

    // If the scheduled time is in the past, don't schedule it (or schedule for next day?)
    // The prompt just says "schedule a local notification to appear at 8 AM on the due date"
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
       // Just to be safe, if it's already past 8 AM today, we might skip or let it fire immediately if flutter_local_notifications allows it.
       // It's usually better to just schedule it anyway, but local notifications will fail if time is in past.
       // Let's add 1 minute from now if it's past 8 AM today, so they still get it.
       if (dueDate.year == DateTime.now().year && dueDate.month == DateTime.now().month && dueDate.day == DateTime.now().day) {
           scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
       } else {
           return; // Past date, do not schedule
       }
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'plant_care_channel',
      'Plant Care Reminders',
      channelDescription: 'Reminders to take care of your plants',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      taskId.hashCode,
      'Time to care for your plant',
      'Your $plantName needs $taskType today. Don\'t forget to check on it.',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleHealthCheckNotification(
      String notificationId, String plantName, DateTime dueDate) async {
    var scheduledDate = tz.TZDateTime.local(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      if (dueDate.year == DateTime.now().year &&
          dueDate.month == DateTime.now().month &&
          dueDate.day == DateTime.now().day) {
        scheduledDate =
            tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      } else {
        return;
      }
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'plant_health_channel',
      'Plant Health Check-ins',
      channelDescription: 'Reminders to check on plant treatment progress',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId.hashCode,
      'Health Check-in Reminder',
      'Your $plantName needs a health check-in. How is the treatment going?',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleDailyFloraInsight() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_insight_channel',
      'Daily Flora Insights',
      channelDescription: 'Daily check-in reminders for your plants',
      importance: Importance.defaultImportance,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    var scheduledDate = tz.TZDateTime.local(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        'Flora has an update for you 🌿',
        'Check in on your plants — your care calendar has updates waiting',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        999,
        'Flora has an update for you 🌿',
        'Check in on your plants — your care calendar has updates waiting',
        RepeatInterval.daily,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
}

