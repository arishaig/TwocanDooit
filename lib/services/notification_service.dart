import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/app_settings.dart';
import '../models/step.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Timer? _nudgeTimer;
  static int _nudgeCount = 0;
  
  static const int _nudgeNotificationId = 1001;
  
  // Notification channel IDs
  static const String _nudgeChannelId = 'nudge_channel';
  static const String _timerChannelId = 'timer_channel';
  static const String _completionChannelId = 'completion_channel';
  static const String _scheduleChannelId = 'schedule_channel';
  static const String _testChannelId = 'test_channel';
  
  // Action IDs for scheduled routine notifications
  static const String _actionStart = 'action_start';
  static const String _actionSnooze = 'action_snooze';
  static const String _actionSkip = 'action_skip';

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
    debugPrint('Notification service initialized');
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    
    // Request permissions for Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      debugPrint('Requesting Android notification permissions...');
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Android notification permissions granted: $granted');
      return granted ?? false;
    }
    
    // Request permissions for iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      debugPrint('Requesting iOS notification permissions...');
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permissions granted: $granted');
      return granted ?? false;
    }
    
    debugPrint('No platform-specific notification plugin found, assuming permissions granted');
    return true; // Assume granted for other platforms
  }


  static Future<void> startNudgeTimer(AppSettings settings, Step currentStep) async {
    if (!settings.nudgeEnabled) return;
    
    await initialize();
    stopNudgeTimer(); // Clear any existing timer
    _nudgeCount = 0;
    
    debugPrint('Starting nudge timer: ${settings.nudgeIntervalMinutes} minutes');
    
    _nudgeTimer = Timer.periodic(
      Duration(minutes: settings.nudgeIntervalMinutes),
      (timer) {
        _nudgeCount++;
        debugPrint('Nudge timer fired: count $_nudgeCount');
        
        if (_nudgeCount >= settings.maxNudgeCount) {
          debugPrint('Max nudge count reached, stopping timer');
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
    debugPrint('Nudge timer stopped');
  }

  static Future<void> _showNudgeNotification(Step step, int nudgeCount) async {
    const androidDetails = AndroidNotificationDetails(
      _nudgeChannelId,
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

    debugPrint('Nudge notification shown: $title - $body');
  }

  static Future<void> dismissNudgeNotification() async {
    if (_isInitialized) {
      await _notifications.cancel(_nudgeNotificationId);
      debugPrint('Nudge notification dismissed');
    }
  }

  static Future<void> _dismissNudgeNotification() async {
    await dismissNudgeNotification();
  }

  static Future<void> showTimerCompletedNotification(String stepTitle) async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      'Timer Completion',
      channelDescription: 'Notifications when timer steps finish',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
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
      2000,
      'Timer Finished! ⏰',
      '"$stepTitle" is complete. Ready for the next step?',
      details,
    );
    
    debugPrint('Timer completion notification shown: $stepTitle');
  }

  static Future<void> showRoutineCompletedNotification(String routineName) async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      _completionChannelId,
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
      _testChannelId,
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
    
    debugPrint('Test notification sent');
  }

  /// Schedule a routine reminder notification
  static Future<void> scheduleRoutineReminder({
    required int notificationId,
    required String scheduleId,
    required String routineId,
    required String routineName,
    required tz.TZDateTime scheduledTime,
    bool isSnooze = false,
  }) async {
    await initialize();
    
    // Create action buttons
    final androidActions = <AndroidNotificationAction>[
      const AndroidNotificationAction(
        _actionStart,
        'Start',
        showsUserInterface: true,
        contextual: true,
      ),
      const AndroidNotificationAction(
        _actionSnooze,
        'Snooze',
        showsUserInterface: false,
        contextual: true,
      ),
      const AndroidNotificationAction(
        _actionSkip,
        'Skip',
        showsUserInterface: false,
        contextual: true,
      ),
    ];
    
    final androidDetails = AndroidNotificationDetails(
      _scheduleChannelId,
      'Routine Reminders',
      channelDescription: 'Scheduled reminders for your routines',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: false,
      ongoing: false,
      actions: androidActions,
      category: AndroidNotificationCategory.reminder,
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

    final title = isSnooze ? 'Routine Reminder (Snoozed)' : 'Routine Reminder';
    final body = 'Time for your routine: $routineName';
    final payload = 'schedule:$scheduleId:$routineId:${isSnooze ? 'snooze' : 'normal'}';

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );

    debugPrint('Scheduled routine reminder: $routineName at ${scheduledTime.toString()}');
  }

  /// Cancel a scheduled notification
  static Future<void> cancelScheduledNotification(int notificationId) async {
    await initialize();
    await _notifications.cancel(notificationId);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllScheduledNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification response (tap or action)
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    debugPrint('Action ID: ${response.actionId}');
    
    if (response.payload?.startsWith('schedule:') == true) {
      _handleScheduleNotificationResponse(response);
    } else if (response.payload?.startsWith('nudge_') == true) {
      _handleNudgeNotificationResponse(response);
    }
  }

  /// Handle schedule notification response
  static void _handleScheduleNotificationResponse(NotificationResponse response) {
    final parts = response.payload!.split(':');
    if (parts.length >= 3) {
      final scheduleId = parts[1];
      final routineId = parts[2];
      final actionId = response.actionId;
      
      debugPrint('Schedule notification response: $scheduleId, $routineId, $actionId');
      
      // Handle different actions
      switch (actionId) {
        case _actionStart:
          _handleStartAction(scheduleId, routineId);
          break;
        case _actionSnooze:
          _handleSnoozeAction(scheduleId);
          break;
        case _actionSkip:
          _handleSkipAction(scheduleId);
          break;
        default:
          // Default tap (no action button) - treat as start
          _handleStartAction(scheduleId, routineId);
          break;
      }
    }
  }

  /// Handle nudge notification response
  static void _handleNudgeNotificationResponse(NotificationResponse response) {
    debugPrint('Nudge notification tapped: ${response.payload}');
    // Handle nudge notification tap - could navigate back to execution screen
  }

  /// Handle start action
  static void _handleStartAction(String scheduleId, String routineId) {
    debugPrint('Start action for schedule: $scheduleId, routine: $routineId');
    // This will be handled by the app's routing system
    // For now, we'll emit an event that can be listened to
    _notificationActionController.add('start:$scheduleId:$routineId');
  }

  /// Handle snooze action
  static void _handleSnoozeAction(String scheduleId) {
    debugPrint('Snooze action for schedule: $scheduleId');
    _notificationActionController.add('snooze:$scheduleId');
  }

  /// Handle skip action
  static void _handleSkipAction(String scheduleId) {
    debugPrint('Skip action for schedule: $scheduleId');
    _notificationActionController.add('skip:$scheduleId');
  }

  // Stream for notification actions
  static final StreamController<String> _notificationActionController = 
      StreamController<String>.broadcast();
  
  /// Stream of notification actions
  static Stream<String> get notificationActionStream => _notificationActionController.stream;

  static Future<void> dispose() async {
    stopNudgeTimer();
    await _dismissNudgeNotification();
    _notificationActionController.close();
  }
}