import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SmartReminderNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const SmartReminderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleSmartKitchenReminders(
    List<SmartReminderNotification> notifications,
  ) async {
    await initialize();
    await cancelSmartKitchenReminders();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'smart_kitchen_reminders',
        'Smart Kitchen Reminders',
        channelDescription: 'Meal routine and planning reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    for (final notification in notifications) {
      if (!notification.scheduledAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: tz.TZDateTime.from(notification.scheduledAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelSmartKitchenReminders() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final item in pending) {
      if (item.id >= 7000 && item.id < 9000) {
        await _plugin.cancel(id: item.id);
      }
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (error) {
      debugPrint('Notification timezone setup failed: $error');
    }
  }
}
