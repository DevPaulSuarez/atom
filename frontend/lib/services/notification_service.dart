import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Programa una notificación local con sonido para que la alarma del Pomodoro
/// suene aunque la app esté en segundo plano o el celular bloqueado (como una
/// alarma normal). En primer plano iOS la silencia y suena la alarma interna.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _alarmId = 1001;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );

      // Permiso explícito (iOS / Android 13+).
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('🔔 NotificationService init falló: $e');
    }
  }

  /// Programa la alarma para el instante [when]. Si ya pasó, no hace nada.
  static Future<void> scheduleAlarm(
    DateTime when, {
    required String title,
    required String body,
  }) async {
    await init();
    if (!when.isAfter(DateTime.now())) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_alarm',
          'Alarma Pomodoro',
          channelDescription: 'Avisa cuando termina un pomodoro o un descanso',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
      await _plugin.zonedSchedule(
        id: _alarmId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('🔔 scheduleAlarm falló: $e');
    }
  }

  /// Cancela la alarma programada (al pausar, saltar, terminar o reiniciar).
  static Future<void> cancelAlarm() async {
    try {
      await _plugin.cancel(id: _alarmId);
    } catch (_) {}
  }
}
