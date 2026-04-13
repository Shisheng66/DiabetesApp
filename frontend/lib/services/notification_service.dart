import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'glucose_reminder_channel';
  static const String _channelName = 'Glucose Reminders';
  static const String _channelDesc = 'Daily glucose reminder notifications';

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Current project target users are in China timezone.
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static Future<void> syncFromBackend() async {
    await init();
    try {
      final res = await ApiService.get('/reminders');
      final list = (res['data'] is List) ? (res['data'] as List) : const [];
      await syncFromReminderList(list);
    } catch (_) {
      // Do not block app startup on reminder sync failures.
    }
  }

  static Future<void> syncFromReminderList(List<dynamic> reminderList) async {
    await init();

    final pending = await _plugin.pendingNotificationRequests();
    for (final req in pending) {
      if (req.payload?.startsWith('reminder:') == true) {
        await _plugin.cancel(req.id);
      }
    }

    for (final item in reminderList) {
      final reminder = _asMap(item);
      final id = _toInt(reminder['id']);
      final enabled = reminder['enabled'] == true;
      final timeRaw = reminder['timeOfDay']?.toString();
      if (id == null || !enabled || timeRaw == null || timeRaw.isEmpty) {
        continue;
      }

      final parsed = _parseTimeOfDay(timeRaw);
      if (parsed == null) continue;

      final title = _buildTitle(reminder);
      final body = _buildBody(reminder);

      await _plugin.zonedSchedule(
        _notificationId(id),
        title,
        body,
        _nextInstanceOf(parsed.$1, parsed.$2),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reminder:$id',
      );
    }
  }

  static int _notificationId(int reminderId) => 50000 + reminderId;

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }
    return schedule;
  }

  static (int, int)? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  static String _buildTitle(Map<String, dynamic> reminder) {
    final type = (reminder['type'] ?? '').toString();
    final remark = (reminder['remark'] ?? '').toString().toUpperCase();
    if (type == 'GLUCOSE_TEST') {
      if (remark == 'FASTING') return '空腹血糖提醒';
      if (remark == 'POST_MEAL') return '餐后血糖提醒';
      if (remark == 'BEFORE_SLEEP') return '睡前血糖提醒';
      return '血糖记录提醒';
    }
    if (type == 'MEDICINE') return '用药提醒';
    if (type == 'EXERCISE') return '运动提醒';
    if (type == 'DIET') return '饮食提醒';
    return '健康提醒';
  }

  static String _buildBody(Map<String, dynamic> reminder) {
    final type = (reminder['type'] ?? '').toString();
    if (type == 'GLUCOSE_TEST') {
      return '请按时记录今天的血糖数据，保持连续追踪。';
    }
    final remark = (reminder['remark'] ?? '').toString().trim();
    if (remark.isNotEmpty) return remark;
    return '记得完成今天的健康任务。';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return const <String, dynamic>{};
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

