import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:home_widget/home_widget.dart';

class StreakUpdater {
  static const String androidWidgetName = 'StreakWidget';

  static Future<void> updateStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userId = user.uid;
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users/$userId/streak')
          .get();

      final streak = snapshot.exists ? snapshot.value as int? ?? 0 : 0;

      // Save streak data to the widget
      await HomeWidget.saveWidgetData<String>(
          'streak_count', streak.toString());
      await HomeWidget.saveWidgetData<String>(
          'streak_message', streak > 0 ? 'Keep it up!' : 'Start your streak!');

      // Update the widget
      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      print('Error updating streak: $e');
    }
  }
}
