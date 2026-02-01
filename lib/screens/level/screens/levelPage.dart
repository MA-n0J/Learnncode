import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/levels/level1.dart';
import 'package:learnncode/screens/level/levels/level2.dart';
import 'package:learnncode/screens/level/levels/level3.dart';
import 'package:learnncode/screens/level/levels/level4.dart';
// import 'package:learnncode/screens/level/levels/level5.dart';
// import 'package:learnncode/screens/level/levels/level6.dart';
// import 'package:learnncode/screens/level/levels/level7.dart';
// import 'package:learnncode/screens/level/levels/level8.dart';
// import 'package:learnncode/screens/level/levels/level9.dart';
// import 'package:learnncode/screens/level/levels/level10.dart';
// import 'package:learnncode/screens/level/levels/level11.dart';
// import 'package:learnncode/screens/level/levels/level12.dart';

class UnifiedLevelPage extends StatefulWidget {
  final int level;

  const UnifiedLevelPage({
    super.key,
    required this.level,
  });

  @override
  State<UnifiedLevelPage> createState() => _UnifiedLevelPageState();
}

class _UnifiedLevelPageState extends State<UnifiedLevelPage> {
  @override
  Widget build(BuildContext context) {
    Widget levelWidget;
    switch (widget.level) {
      case 1:
        levelWidget = Level1(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 2:
        levelWidget = Level2(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 3:
        levelWidget = Level3(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 4:
        levelWidget = Level4(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      /*
      case 5:
        levelWidget = Level5(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 6:
        levelWidget = Level6(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 7:
        levelWidget = Level7(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 8:
        levelWidget = Level8(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 9:
        levelWidget = Level9(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 10:
        levelWidget = Level10(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 11:
        levelWidget = Level11(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      case 12:
        levelWidget = Level12(
          onComplete: (isCompleted, score, totalQuestions) {
            Navigator.pop(context, {
              'isCompleted': isCompleted,
              'score': score,
              'totalQuestions': totalQuestions,
            });
          },
        );
        break;
      */
      default:
        levelWidget = const Center(child: Text('Level not implemented'));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: levelWidget,
      ),
    );
  }
}
