import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'package:learnncode/firebase_options.dart';
import 'dart:math';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _database = FirebaseDatabase.instance.ref();
  static const String _taskName = 'learningReminderTask';
  static final Random _random = Random();

  // Morning Messages (9 AM - 12 PM)
  static const List<Map<String, String>> _morningMessages = [
    {
      'title': '🌞 Rise and Learn!',
      'body':
          'Start your morning strong—keep your streak alive with a lesson! 🚀',
    },
    {
      'title': '☀️ Morning Mastery!',
      'body': 'Kick off your day with a lesson and grow your streak! 🌟',
    },
    {
      'title': '🏁 Fresh Start!',
      'body': 'A new day, a new lesson—let’s keep that streak going! 💪',
    },
    {
      'title': '🌅 Wake Up & Win!',
      'body': 'Rise up and tackle a lesson to boost your streak! 🏆',
    },
    {
      'title': '☕ Morning Motivation!',
      'body': 'Grab your coffee and a lesson—your streak awaits! 🔥',
    },
    {
      'title': '🌞 Start Strong!',
      'body': 'Make your morning count with a quick lesson—streak on! 🚀',
    },
    {
      'title': '🐾 Early Bird Learns!',
      'body': 'Get a head start with a lesson and keep your streak soaring! 🌟',
    },
    {
      'title': '🌄 New Day, New Lesson!',
      'body': 'Begin your day with a lesson and watch your streak shine! 💡',
    },
    {
      'title': '🌞 Morning Vibes!',
      'body': 'Let’s make today awesome—start with a lesson and streak! 🎯',
    },
    {
      'title': '☀️ Bright Start!',
      'body':
          'Light up your morning with a lesson and keep that streak alive! 🌈',
    },
  ];

  // Afternoon Messages (12 PM - 11 PM)
  static const List<Map<String, String>> _afternoonMessages = [
    {
      'title': '📚 Keep the Momentum!',
      'body': 'Don’t miss out—dive into a lesson this afternoon! 🌟',
    },
    {
      'title': '🕒 Midday Mastery!',
      'body': 'Take a break and learn something new—your streak loves it! 🚀',
    },
    {
      'title': '🌟 Afternoon Boost!',
      'body': 'Power through your day with a lesson and keep your streak! 💪',
    },
    {
      'title': '📖 Learn On!',
      'body':
          'Make your afternoon count—tackle a lesson and grow your streak! 🏆',
    },
    {
      'title': '☀️ Keep Shining!',
      'body': 'Your streak is glowing—add a lesson this afternoon! 🔥',
    },
    {
      'title': '🏋️ Midday Challenge!',
      'body':
          'Flex your brain with a lesson—your streak is counting on you! 🌟',
    },
    {
      'title': '📝 Afternoon Action!',
      'body': 'Let’s keep learning—do a lesson and boost your streak! 🚀',
    },
    {
      'title': '🌞 Stay on Track!',
      'body': 'Don’t slow down—hit a lesson this afternoon for your streak! 💡',
    },
    {
      'title': '🎯 Midday Goal!',
      'body': 'Aim high with a lesson this afternoon—your streak’s waiting! 🏆',
    },
    {
      'title': '📚 Afternoon Adventure!',
      'body': 'Explore a new lesson today—your streak will thank you! 🌈',
    },
  ];

  // Late Night Messages (11 PM - 12 AM)
  static const List<Map<String, String>> _lateNightMessages = [
    {
      'title': '⏰ Last Call!',
      'body': 'Hurry, do a lesson before midnight to save your streak! 🔥',
    },
    {
      'title': '🌙 Final Countdown!',
      'body':
          'Don’t lose your streak—complete a lesson before the day ends! 🚨',
    },
    {
      'title': '⏳ Time’s Ticking!',
      'body': 'Last chance to keep your streak—do a lesson now! 💥',
    },
    {
      'title': '🕚 Nighttime Rush!',
      'body': 'Protect your streak—squeeze in a lesson before midnight! 🌟',
    },
    {
      'title': '🔥 Streak Saver!',
      'body': 'Don’t let your streak slip—do a lesson before it’s too late! 🚀',
    },
    {
      'title': '⏰ Almost Midnight!',
      'body': 'Quick, a lesson now keeps your streak alive—don’t miss out! 💪',
    },
    {
      'title': '🌙 End the Day Right!',
      'body':
          'Finish strong—do a lesson to save your streak before midnight! 🏆',
    },
    {
      'title': '🕛 Last Minute Hero!',
      'body':
          'Be the streak hero—complete a lesson before the clock strikes 12! 🔥',
    },
    {
      'title': '⏳ Don’t Miss Out!',
      'body': 'Your streak’s on the line—do a lesson before the day’s over! 🌟',
    },
    {
      'title': '🌜 Night Owl Challenge!',
      'body': 'Keep your streak soaring—do a lesson before midnight hits! 🚀',
    },
  ];

  static Future<void> initialize() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    print('Notification permission status: $notificationStatus');
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      print('Notification permission denied, prompting user');
      await openAppSettings();
    }

    // Request battery optimization exemption for exact timing on Android
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
      print('Requested battery optimization exemption');
    }

    // Initialize timezone
    tz.initializeTimeZones();
    final location = tz.getLocation('UTC'); // Use your timezone if needed
    tz.setLocalLocation(location);

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
    print('Local notifications initialized');

    // Initialize WorkManager for rescheduling
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(days: 1), // Run once a day
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    print('WorkManager task scheduled to reschedule notifications daily');

    // Schedule notifications immediately
    await scheduleNotifications();
  }

  // Calculate initial delay to run Workmanager at 1 AM
  static Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 1, 0); // 1 AM today
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1)); // 1 AM tomorrow
    }
    return nextRun.difference(now);
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'learning_channel',
      'Learning Notifications',
      channelDescription: 'Notifications for learning activities',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      print(
          'Scheduling notification (ID: $id) at $scheduledTime: $title - $body');
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static Future<void> scheduleNotifications() async {
    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized');
    } catch (e) {
      print('Error initializing Firebase: $e');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return;
    }

    final hasCompleted = await hasCompletedLessonToday(userId);
    if (hasCompleted) {
      print('User $userId already completed lesson today, skipping scheduling');
      await cancelAllNotifications();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule Morning Notification (9 AM)
    final morningTime = today.add(const Duration(hours: 9));
    if (now.isBefore(morningTime)) {
      final message =
          _morningMessages[_random.nextInt(_morningMessages.length)];
      await _scheduleNotification(
        id: 1,
        title: message['title']!,
        body: message['body']!,
        scheduledTime: morningTime,
      );
    }

    // Schedule Afternoon Notifications (12 PM, 2 PM, 4 PM, 6 PM, 8 PM, 10 PM)
    final afternoonHours = [12, 14, 16, 18, 20, 22];
    for (int i = 0; i < afternoonHours.length; i++) {
      final afternoonTime = today.add(Duration(hours: afternoonHours[i]));
      if (now.isBefore(afternoonTime)) {
        final message =
            _afternoonMessages[_random.nextInt(_afternoonMessages.length)];
        await _scheduleNotification(
          id: 2 + i, // Unique ID for each afternoon notification
          title: message['title']!,
          body: message['body']!,
          scheduledTime: afternoonTime,
        );
      }
    }

    // Schedule Late Night Notifications (11:00 PM, 11:15 PM, 11:30 PM, 11:45 PM)
    final lateNightMinutes = [0, 15, 30, 45];
    for (int i = 0; i < lateNightMinutes.length; i++) {
      final lateNightTime =
          today.add(Duration(hours: 23, minutes: lateNightMinutes[i]));
      if (now.isBefore(lateNightTime)) {
        final message =
            _lateNightMessages[_random.nextInt(_lateNightMessages.length)];
        await _scheduleNotification(
          id: 8 + i, // Unique ID for each late night notification
          title: message['title']!,
          body: message['body']!,
          scheduledTime: lateNightTime,
        );
      }
    }

    print('Notifications scheduled for today');
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  static Future<void> markLessonCompleted(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _database.child('users/$userId/lastLessonDate').set(today);
      print('Marked lesson completed for user $userId on $today');
      await cancelAllNotifications(); // Cancel all scheduled notifications
    } catch (e) {
      print('Error marking lesson completed: $e');
    }
  }

  static Future<bool> hasCompletedLessonToday(String userId) async {
    try {
      final snapshot =
          await _database.child('users/$userId/lastLessonDate').get();
      if (snapshot.exists) {
        final lastLessonDate = snapshot.value as String;
        final today = DateTime.now().toIso8601String().split('T')[0];
        return lastLessonDate == today;
      }
      return false;
    } catch (e) {
      print('Error checking lesson completion: $e');
      return false;
    }
  }

  // Test method to trigger all notifications immediately (for debugging)
  static Future<void> triggerAllNotificationsForTesting() async {
    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized for testing');
    } catch (e) {
      print('Error initializing Firebase for testing: $e');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in for testing');
      return;
    }

    final hasCompleted = await hasCompletedLessonToday(userId);
    if (hasCompleted) {
      print(
          'User $userId already completed lesson today, skipping test notifications');
      return;
    }

    // Trigger all notifications with slight delays to ensure they stack
    final morningMessage =
        _morningMessages[_random.nextInt(_morningMessages.length)];
    const androidDetails = AndroidNotificationDetails(
      'learning_channel',
      'Learning Notifications',
      channelDescription: 'Notifications for learning activities',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      morningMessage['title']!,
      morningMessage['body']!,
      notificationDetails,
    );
    await Future.delayed(const Duration(seconds: 1));
    final afternoonMessage =
        _afternoonMessages[_random.nextInt(_afternoonMessages.length)];
    await _notifications.show(
      2,
      afternoonMessage['title']!,
      afternoonMessage['body']!,
      notificationDetails,
    );
    await Future.delayed(const Duration(seconds: 1));
    final lateNightMessage =
        _lateNightMessages[_random.nextInt(_lateNightMessages.length)];
    await _notifications.show(
      3,
      lateNightMessage['title']!,
      lateNightMessage['body']!,
      notificationDetails,
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('WorkManager task $task executed');
    await NotificationService.scheduleNotifications();
    return Future.value(true);
  });
}
