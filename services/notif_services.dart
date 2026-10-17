import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotifServices {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Channel ID & Name
  static const String _channelId = 'tugas_kuliah_channel';
  static const String _channelName = 'Pengingat Tugas Kuliah';
  static const String _channelDesc = 'Notifikasi pengingat deadline tugas kuliah';

  static Future<void> initialize() async {
    if (_initialized) return;

    // Init timezone
    tz_data.initializeTimeZones();

    // Android init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init - minta permission langsung
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap notifikasi (opsional)
        debugPrint('Notifikasi di-tap: ${details.payload}');
      },
    );

    // Buat notification channel untuk Android 8+
    await _createNotificationChannel();

    // Minta permission Android 13+
    await _requestPermissions();

    _initialized = true;
    debugPrint('NotifServices: initialized');
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _requestPermissions() async {
    // Android 13+ perlu minta izin notifikasi
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidImpl?.requestNotificationsPermission();
    debugPrint('NotifServices: permission granted = $granted');

    // Minta izin exact alarm (Android 12+)
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Jadwalkan notifikasi tepat pada waktu deadline
  static Future<void> scheduleDeadlineNotification({
    required int id,
    required String namaTugas,
    required String mataKuliah,
    required DateTime deadline,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();

    // Notifikasi 1: H-1 sebelum deadline (jam 08.00)
    final hMin1 = DateTime(
      deadline.year,
      deadline.month,
      deadline.day - 1,
      8,
      0,
    );

    // Notifikasi 2: Tepat saat deadline
    final tepatDeadline = deadline;

    // Notifikasi 3: 1 jam sebelum deadline
    final satuJamSebelum = deadline.subtract(const Duration(hours: 1));

    if (hMin1.isAfter(now)) {
      await _scheduleOne(
        id: id * 10 + 1,
        title: '⏰ Deadline Besok!',
        body: '$namaTugas ($mataKuliah) deadline besok jam ${_jamStr(deadline)}',
        scheduledDate: hMin1,
        payload: '$id',
      );
      debugPrint('NotifServices: dijadwalkan H-1 = $hMin1');
    }

    if (satuJamSebelum.isAfter(now)) {
      await _scheduleOne(
        id: id * 10 + 2,
        title: '🚨 1 Jam Lagi Deadline!',
        body: 'Segera selesaikan $namaTugas ($mataKuliah)',
        scheduledDate: satuJamSebelum,
        payload: '$id',
      );
      debugPrint('NotifServices: dijadwalkan 1 jam sebelum = $satuJamSebelum');
    }

    if (tepatDeadline.isAfter(now)) {
      await _scheduleOne(
        id: id * 10 + 3,
        title: '🔔 Deadline Sekarang!',
        body: '$namaTugas ($mataKuliah) sudah deadline!',
        scheduledDate: tepatDeadline,
        payload: '$id',
      );
      debugPrint('NotifServices: dijadwalkan tepat deadline = $tepatDeadline');
    }
  }

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotifServices: error scheduling = $e');
    }
  }

  /// Tampilkan notifikasi langsung (untuk test)
  static Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      0,
      '✅ Notifikasi Aktif',
      'Pengingat tugas kuliah berhasil diaktifkan!',
      details,
    );
  }

  /// Batalkan semua notifikasi untuk 1 tugas
  static Future<void> cancelTugasNotifications(int tugasId) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(tugasId * 10 + 1);
    await _plugin.cancel(tugasId * 10 + 2);
    await _plugin.cancel(tugasId * 10 + 3);
  }

  /// Batalkan semua notifikasi
  static Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  static String _jamStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}