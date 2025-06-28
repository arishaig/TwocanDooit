import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_settings.dart';
import '../models/step.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Timer? _nudgeTimer;
  static int _nudgeCount = 0;
  
  static const int _nudgeNotificationId = 1001;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('Notification service initialized');
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    
    // Request permissions for Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      print('Requesting Android notification permissions...');
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Android notification permissions granted: $granted');
      return granted ?? false;
    }
    
    // Request permissions for iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      print('Requesting iOS notification permissions...');
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS notification permissions granted: $granted');
      return granted ?? false;
    }
    
    print('No platform-specific notification plugin found, assuming permissions granted');
    return true; // Assume granted for other platforms
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate back to execution screen
  }

  static Future<void> startNudgeTimer(AppSettings settings, Step currentStep) async {
    if (!settings.nudgeEnabled) return;
    
    await initialize();
    stopNudgeTimer(); // Clear any existing timer
    _nudgeCount = 0;
    
    print('Starting nudge timer: ${settings.nudgeIntervalMinutes} minutes');
    
    _nudgeTimer = Timer.periodic(
      Duration(minutes: settings.nudgeIntervalMinutes),
      (timer) {
        _nudgeCount++;
        print('Nudge timer fired: count $_nudgeCount');
        
        if (_nudgeCount >= settings.maxNudgeCount) {
          print('Max nudge count reached, stopping timer');
          stopNudgeTimer();
          return;
        }
        
        _showNudgeNotification(currentStep, _nudgeCount);
      },
    );
  }

  static void stopNudgeTimer() {
    _nudgeTimer?.cancel();
    _nudgeTimer = null;
    _nudgeCount = 0;
    // Don't automatically dismiss - let user see the notification
    // _dismissNudgeNotification();
    print('Nudge timer stopped');
  }

  static Future<void> _showNudgeNotification(Step step, int nudgeCount) async {
    const androidDetails = AndroidNotificationDetails(
      'nudge_channel',
      'Routine Nudges',
      channelDescription: 'Notifications to remind you to continue your routine',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      ongoing: true, // Make it persistent
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'Don\'t forget your routine!';
    final body = 'You\'ve been on "${step.title}" for a while. Ready to continue?';

    await _notifications.show(
      _nudgeNotificationId,
      title,
      body,
      details,
      payload: 'nudge_${step.id}',
    );

    print('Nudge notification shown: $title - $body');
  }

  static Future<void> _dismissNudgeNotification() async {
    await _notifications.cancel(_nudgeNotificationId);
    print('Nudge notification dismissed');
  }

  static Future<void> showRoutineCompletedNotification(String routineName) async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      'completion_channel',
      'Routine Completion',
      channelDescription: 'Notifications when routines are completed',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2001,
      'Routine Complete! 🎉',
      'Great job finishing "$routineName"!',
      details,
    );
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications to verify system is working',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      9999,
      'Dooit Notifications Ready!',
      'Notification system is working correctly.',
      details,
    );
    
    print('Test notification sent');
  }

  static Future<void> dispose() async {
    stopNudgeTimer();
    await _dismissNudgeNotification();
  }
}