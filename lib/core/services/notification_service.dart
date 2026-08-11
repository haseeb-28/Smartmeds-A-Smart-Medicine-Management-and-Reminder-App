import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Wraps flutter_local_notifications for medicine reminders.
///
/// Setup required outside this file (see README):
/// - Android: add POST_NOTIFICATIONS + SCHEDULE_EXACT_ALARM permissions
///   to AndroidManifest.xml, and the notification icon drawable.
/// - iOS: enable notification capability in Xcode, request permission
///   (handled in [initialize] below via the iOS plugin implementation).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Called from action buttons ("Take Now" / "Skip" / "Snooze") on a
  /// notification. The dashboard/reminders layer sets this to hook the
  /// response back into the medicine_history table.
  void Function(String payload, String actionId)? onActionTapped;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';
        final actionId = response.actionId ?? 'open';
        onActionTapped?.call(payload, actionId);
      },
    );

    _initialized = true;
  }

  static const _takeAction = AndroidNotificationAction(
    'take_now',
    'Take Now',
    showsUserInterface: false,
  );
  static const _skipAction = AndroidNotificationAction(
    'skip',
    'Skip',
    showsUserInterface: false,
  );
  static const _snoozeAction = AndroidNotificationAction(
    'snooze_10',
    'Snooze 10m',
    showsUserInterface: false,
  );

  /// Schedules a one-off reminder for a specific dose (e.g. today's
  /// 8:00 AM Metformin). [payload] should be the medicine_history row id
  /// so the action callback knows which dose to update.
  Future<void> scheduleDoseReminder({
    required int notificationId,
    required String medicineName,
    required String dosageLabel,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders to take your medicine on time',
        importance: Importance.max,
        priority: Priority.high,
        actions: [_takeAction, _skipAction, _snoozeAction],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'medicine_reminder',
      ),
    );

    await _plugin.zonedSchedule(
      notificationId,
      'Time to take $medicineName',
      dosageLabel,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  /// Reschedules an already-fired reminder for [minutesFromNow] later —
  /// used by the "Snooze 10m" notification action. Uses a one-off
  /// (non-repeating) schedule so it doesn't collide with tomorrow's
  /// regular daily reminder at the same notification id.
  Future<void> snoozeReminder({
    required int notificationId,
    required String medicineName,
    required String dosageLabel,
    required String payload,
    int minutesFromNow = 10,
  }) async {
    await initialize();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutesFromNow));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders to take your medicine on time',
        importance: Importance.max,
        priority: Priority.high,
        actions: [_takeAction, _skipAction, _snoozeAction],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'medicine_reminder',
      ),
    );

    await _plugin.zonedSchedule(
      notificationId + 500000,
      'Time to take $medicineName',
      '$dosageLabel · snoozed',
      tz.TZDateTime.from(snoozeTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Fires immediately (not scheduled) — used for stock alerts, which
  /// are event-driven ("stock just dropped below threshold"), not
  /// time-driven like dose reminders.
  Future<void> showStockAlert({
    required int notificationId,
    required String medicineName,
    required bool isOutOfStock,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'stock_alerts',
        'Stock Alerts',
        channelDescription: 'Alerts when a medicine is running low or out of stock',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      notificationId,
      isOutOfStock ? 'Medicine finished' : 'Medicine stock low',
      isOutOfStock
          ? '$medicineName is out of stock. Time to refill.'
          : '$medicineName is running low. Consider refilling soon.',
      details,
    );
  }

  /// Module 12: Caregiver Support. Fires when a FAMILY MEMBER's dose
  /// (not the account holder's own) goes unconfirmed past the grace
  /// window — named explicitly ("Mother missed her 2:00 PM Metformin")
  /// since the whole point is telling the caregiver *who* needs
  /// attention, which a generic "dose missed" alert wouldn't convey.
  Future<void> showCaregiverAlert({
    required int notificationId,
    required String patientName,
    required String medicineName,
    required String timeLabel,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'caregiver_alerts',
        'Caregiver Alerts',
        channelDescription:
            'Alerts when a family member misses a scheduled dose',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      notificationId,
      '$patientName missed a dose',
      '$patientName missed their $timeLabel $medicineName.',
      details,
    );
  }

  /// Stable-ish int id derived from a schedule row's UUID, since
  /// flutter_local_notifications needs an int id per notification.
  static int idFromScheduleId(String scheduleId) =>
      scheduleId.hashCode & 0x7fffffff;

  /// Separate id space (offset) for stock alerts so they never collide
  /// with a schedule's dose-reminder notification id.
  static int idFromMedicineId(String medicineId) =>
      (medicineId.hashCode & 0x7fffffff) ~/ 2 + 1000000;

  /// Separate id space for caregiver alerts, keyed by the dose
  /// (medicine_history row) id so each missed dose gets its own
  /// notification rather than overwriting a prior one.
  static int idFromDoseId(String doseId) =>
      (doseId.hashCode & 0x7fffffff) ~/ 2 + 2000000;
}
