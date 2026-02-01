import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  int _xp = 0;
  int _streak = 0;
  Map<String, bool> _unitProgress = {};
  bool _isLessonCompletedToday = false;
  String? _lastLessonDate;
  int _unlockedLevels = 1;
  Map<String, int> _dailyXP = {};
  Map<String, int> _dailyScreenTime = {};
  String? _currentUserId;
  bool _isResetting = false;
  bool _isInitialized = false;

  DateTime? _sessionStartTime;
  int _currentSessionSeconds = 0; // Track in seconds for precision
  Timer? _screenTimeTimer;

  int get xp => _xp;
  int get streak => _streak;
  Map<String, bool> get unitProgress => _unitProgress;
  bool get isLessonCompletedToday => _isLessonCompletedToday;
  int get unlockedLevels => _unlockedLevels;
  Map<String, int> get dailyXP => _dailyXP;
  Map<String, int> get dailyScreenTime => _dailyScreenTime;

  final FirebaseDatabase database = FirebaseDatabase.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  AppState() {
    _initializeDefaults();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer here
    auth.authStateChanges().listen((User? user) async {
      if (_isResetting) return;
      if (user == null) {
        resetState(notify: false);
      } else if (user.uid != _currentUserId) {
        _currentUserId = user.uid;
        await _loadState();
      }
    });

    if (auth.currentUser != null) {
      _currentUserId = auth.currentUser!.uid;
      _loadState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startTrackingScreenTime();
    } else if (state == AppLifecycleState.paused) {
      stopTrackingScreenTime();
    }
  }

  void _initializeDefaults() {
    _xp = 0;
    _streak = 0;
    _unitProgress = {};
    _isLessonCompletedToday = false;
    _lastLessonDate = null;
    _unlockedLevels = 1;
    _dailyXP = {};
    _dailyScreenTime = {};
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      _dailyXP[dateKey] = 0;
      _dailyScreenTime[dateKey] = 0;
    }
  }

  void resetState({bool notify = true}) {
    if (_isResetting) return;
    _isResetting = true;

    _screenTimeTimer?.cancel();
    _initializeDefaults();
    _currentUserId = null;
    _sessionStartTime = null;
    _currentSessionSeconds = 0;

    print('AppState reset');
    if (notify && _isInitialized) {
      notifyListeners();
    }
    _isResetting = false;
  }

  Future<void> _loadState() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      resetState(notify: false);
      return;
    }

    try {
      final snapshot = await database.ref().child('users/$userId').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _xp = data['xp'] ?? 0;
        _streak = data['streak'] ?? 0;
        _lastLessonDate = data['lastLessonDate'] ?? null;
        _unitProgress = Map<String, bool>.from(data['unitProgress'] ?? {});
        _unlockedLevels = data['unlockedLevels'] ?? 1;
        _isLessonCompletedToday = await _checkLessonCompletedToday(userId);

        final dailyXPSnapshot =
            await database.ref().child('users/$userId/dailyXP').get();
        if (dailyXPSnapshot.exists) {
          final dailyXPData = dailyXPSnapshot.value as Map<dynamic, dynamic>;
          _dailyXP = dailyXPData
              .map((key, value) => MapEntry(key.toString(), value as int));
        }

        final dailyScreenTimeSnapshot =
            await database.ref().child('users/$userId/dailyScreenTime').get();
        if (dailyScreenTimeSnapshot.exists) {
          final screenTimeData =
              dailyScreenTimeSnapshot.value as Map<dynamic, dynamic>;
          _dailyScreenTime = screenTimeData
              .map((key, value) => MapEntry(key.toString(), value as int));
        }

        final today = DateTime.now();
        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final dateKey = date.toIso8601String().split('T')[0];
          _dailyXP[dateKey] ??= 0;
          _dailyScreenTime[dateKey] ??= 0;
        }

        final keysToRemove = _dailyXP.keys.where((key) {
          final date = DateTime.parse(key);
          return today.difference(date).inDays > 6;
        }).toList();
        for (final key in keysToRemove) {
          _dailyXP.remove(key);
          _dailyScreenTime.remove(key);
          await database.ref().child('users/$userId/dailyXP/$key').remove();
          await database
              .ref()
              .child('users/$userId/dailyScreenTime/$key')
              .remove();
        }

        print(
            'Loaded state for user $userId: xp=$_xp, streak=$_streak, unitProgress=$_unitProgress, unlockedLevels=$_unlockedLevels, dailyXP=$_dailyXP, dailyScreenTime=$_dailyScreenTime');
      } else {
        print('No user data found for user $userId, initializing defaults');
        resetState(notify: false);
        await database.ref().child('users/$userId').set({
          'xp': 0,
          'streak': 0,
          'lastLessonDate': null,
          'unitProgress': {},
          'unlockedLevels': 1,
          'dailyXP': _dailyXP,
          'dailyScreenTime': _dailyScreenTime,
        });
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading state for user $userId: $e');
    }
  }

  Future<bool> _checkLessonCompletedToday(String userId) async {
    try {
      final snapshot =
          await database.ref().child('users/$userId/lastLessonDate').get();
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

  Future<void> completeLesson({required String unitId, int xpGain = 50}) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final wasCompletedToday = await _checkLessonCompletedToday(userId);

      _unitProgress[unitId] = true;
      _xp += xpGain;
      _dailyXP[today] = (_dailyXP[today] ?? 0) + xpGain;
      await database
          .ref()
          .child('users/$userId/dailyXP/$today')
          .set(_dailyXP[today]);

      if (!wasCompletedToday) {
        if (_lastLessonDate != null) {
          final lastDate = DateTime.parse(_lastLessonDate!);
          final todayDate = DateTime.parse(today);
          final difference = todayDate.difference(lastDate).inDays;
          if (difference <= 1) {
            _streak += 1;
          } else {
            _streak = 1;
          }
        } else {
          _streak = 1;
        }
        _isLessonCompletedToday = true;
        _lastLessonDate = today;
      }

      _unlockedLevels = (_unlockedLevels + 1).clamp(1, 10);

      await database.ref().child('users/$userId').update({
        'unitProgress': _unitProgress,
        'xp': _xp,
        'streak': _streak,
        'lastLessonDate': today,
        'unlockedLevels': _unlockedLevels,
      });

      print(
          'Lesson completed for user $userId: dailyXP=$_dailyXP, unitId=$unitId, xp=$_xp, streak=$_streak, unlockedLevels=$_unlockedLevels');
      notifyListeners();
    } catch (e) {
      print('Error completing lesson for user $userId: $e');
    }
  }

  Future<void> resetProgress() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      resetState(notify: false);
      return;
    }

    try {
      resetState(notify: false);
      await database.ref().child('users/$userId').set({
        'unitProgress': {},
        'xp': 0,
        'streak': 0,
        'lastLessonDate': null,
        'unlockedLevels': 1,
        'dailyXP': _dailyXP,
        'dailyScreenTime': _dailyScreenTime,
      });

      print('Progress reset for user $userId');
      notifyListeners();
    } catch (e) {
      print('Error resetting progress for user $userId: $e');
    }
  }

  void startTrackingScreenTime() {
    _sessionStartTime = DateTime.now();
    print('Started tracking screen time at $_sessionStartTime');

    _screenTimeTimer?.cancel();
    _screenTimeTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_sessionStartTime == null) {
        timer.cancel();
        print('Session start time is null, stopping timer');
        return;
      }

      final userId = auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in, stopping screen time tracking');
        timer.cancel();
        return;
      }

      try {
        final now = DateTime.now();
        final sessionDuration = now.difference(_sessionStartTime!).inSeconds;
        final today = DateTime.now().toIso8601String().split('T')[0];

        _currentSessionSeconds += sessionDuration;
        final totalMinutes = _currentSessionSeconds ~/ 60;
        _dailyScreenTime[today] = (_dailyScreenTime[today] ?? 0) + totalMinutes;

        if (totalMinutes > 0) {
          await database
              .ref()
              .child('users/$userId/dailyScreenTime/$today')
              .set(_dailyScreenTime[today]);
          print(
              'Updated screen time. Session duration: $sessionDuration seconds, Total today: ${_dailyScreenTime[today]} minutes');
          _currentSessionSeconds =
              _currentSessionSeconds % 60; // Reset remainder
        } else {
          print(
              'Session duration too short to update: $sessionDuration seconds');
        }

        _sessionStartTime = now;
        notifyListeners();
      } catch (e) {
        print('Error updating screen time for user $userId: $e');
      }
    });
  }

  Future<void> stopTrackingScreenTime() async {
    if (_sessionStartTime == null) {
      print('No active session to stop');
      return;
    }

    final userId = auth.currentUser?.uid;
    if (userId == null) {
      print('No user logged in, cannot track screen time');
      _screenTimeTimer?.cancel();
      _sessionStartTime = null;
      return;
    }

    try {
      final sessionEndTime = DateTime.now();
      final sessionDuration =
          sessionEndTime.difference(_sessionStartTime!).inSeconds;
      _currentSessionSeconds += sessionDuration;
      final totalMinutes = _currentSessionSeconds ~/ 60;

      final today = DateTime.now().toIso8601String().split('T')[0];
      _dailyScreenTime[today] = (_dailyScreenTime[today] ?? 0) + totalMinutes;

      if (totalMinutes > 0) {
        await database
            .ref()
            .child('users/$userId/dailyScreenTime/$today')
            .set(_dailyScreenTime[today]);
        print(
            'Stopped tracking screen time. Session duration: $sessionDuration seconds, Total today: ${_dailyScreenTime[today]} minutes');
      } else {
        print('Session duration too short to stop: $sessionDuration seconds');
      }

      _sessionStartTime = null;
      _currentSessionSeconds = 0;
      _screenTimeTimer?.cancel();
      notifyListeners();
    } catch (e) {
      print('Error uploading screen time for user $userId: $e');
    }
  }

  @override
  void dispose() {
    _screenTimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
