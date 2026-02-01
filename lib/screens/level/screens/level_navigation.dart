import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnncode/providers/state_manager.dart';
import 'dart:math';

import 'levelPage.dart';

class LevelDesign extends StatefulWidget {
  final int unitIndex;
  final Function(String, int) onLevelCompleted;

  const LevelDesign({
    super.key,
    required this.unitIndex,
    required this.onLevelCompleted,
  });

  @override
  LevelDesignState createState() => LevelDesignState();
}

class LevelDesignState extends State<LevelDesign> {
  int unlockedLevels = 1;

  @override
  void initState() {
    super.initState();
    print('LevelDesign: initState called for unitIndex=${widget.unitIndex}');
    _loadUnlockedLevels();
  }

  Future<void> _loadUnlockedLevels() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.auth.currentUser?.uid;
    if (userId == null) {
      print('LevelDesign: No user logged in');
      return;
    }

    try {
      final snapshot = await appState.database
          .ref()
          .child('users/$userId/unlockedLevels')
          .get();
      if (snapshot.exists) {
        setState(() {
          unlockedLevels = snapshot.value as int;
          print('LevelDesign: Loaded unlockedLevels: $unlockedLevels');
        });
      }
    } catch (e) {
      print('LevelDesign: Error loading unlockedLevels: $e');
    }
  }

  Future<void> _markLevelAsCompleted(int level) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final unitId = 'unit${widget.unitIndex + 1}_level$level';
    print('LevelDesign: Marking $unitId as completed');
    await appState.completeLesson(unitId: unitId, xpGain: 25);

    // Notify LevelDesignScreen to send the notification
    widget.onLevelCompleted(unitId, level);

    if (level < 40 && unlockedLevels == level) {
      setState(() {
        unlockedLevels = level + 1;
        print('LevelDesign: Unlocked level $unlockedLevels');
      });
      final userId = appState.auth.currentUser?.uid;
      if (userId != null) {
        await appState.database
            .ref()
            .child('users/$userId/unlockedLevels')
            .set(unlockedLevels);
      }
    }
  }

  bool _calculateProgress(int level) {
    final appState = Provider.of<AppState>(context, listen: false);
    final unitId = 'unit${widget.unitIndex + 1}_level$level';
    return appState.unitProgress[unitId] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    print('LevelDesign: Building UI for unitIndex=${widget.unitIndex}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Unit ${widget.unitIndex + 1}",
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('LevelDesign: Back button pressed');
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.resetProgress();
              setState(() {
                unlockedLevels = 1;
                print('LevelDesign: Cleared all progress');
              });
              final userId = appState.auth.currentUser?.uid;
              if (userId != null) {
                await appState.database
                    .ref()
                    .child('users/$userId/unlockedLevels')
                    .set(1);
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          const double appBarHeight = 0.0;
          final double availableHeight = height - appBarHeight;

          const double verticalSpacingFactor = 0.2;
          const double horizontalSpacingFactor = 0.3;

          const int nodeCount = 4;
          final double totalNodeSpace =
              availableHeight * verticalSpacingFactor * (nodeCount - 1);
          final double topOffset = (availableHeight - totalNodeSpace) / 2;

          final List<Offset> nodePositions = List.generate(nodeCount, (index) {
            final double yPosition = appBarHeight +
                topOffset +
                (availableHeight * verticalSpacingFactor * index);
            final double xPosition = index % 2 == 0
                ? width * horizontalSpacingFactor
                : width * (1 - horizontalSpacingFactor);
            return Offset(xPosition, yPosition);
          });

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ZigzagSquareLinePainter(nodePositions),
                ),
              ),
              for (int index = 0; index < nodePositions.length; index++)
                Positioned(
                  left: nodePositions[index].dx - 40,
                  top: nodePositions[index].dy - 40,
                  child: GestureDetector(
                    onTap: index < unlockedLevels
                        ? () async {
                            print('LevelDesign: Tapped Level ${index + 1}');
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UnifiedLevelPage(
                                  level: index + 1,
                                ),
                              ),
                            );
                            if (result is Map &&
                                result['isCompleted'] == true) {
                              print(
                                  'LevelDesign: Marking level ${index + 1} as completed, score: ${result['score']}/${result['totalQuestions']}');
                              await _markLevelAsCompleted(index + 1);
                            }
                          }
                        : () {
                            print('LevelDesign: Level ${index + 1} is locked');
                          },
                    child: Column(
                      children: [
                        NodeWithProgress(
                          icon: index < unlockedLevels
                              ? (_calculateProgress(index + 1)
                                  ? Icons.check_circle
                                  : Icons.play_arrow)
                              : Icons.lock,
                          progress: _calculateProgress(index + 1) ? 1.0 : 0.0,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${index + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class NodeWithProgress extends StatelessWidget {
  final IconData icon;
  final double progress;

  const NodeWithProgress({
    super.key,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ProgressCirclePainter(progress),
      child: CircleItem(icon: icon, borderColor: Colors.black),
    );
  }
}

class CircleItem extends StatelessWidget {
  final IconData icon;
  final Color borderColor;

  const CircleItem({
    super.key,
    required this.icon,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 3),
        borderRadius: BorderRadius.circular(40),
        color: Colors.white,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: borderColor,
        ),
      ),
    );
  }
}

class ProgressCirclePainter extends CustomPainter {
  final double progress;

  ProgressCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final outerRadius = size.width / 2 + 10;
    final center = Offset(size.width / 2, size.height / 2);

    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, outerRadius, backgroundPaint);

    final progressPaint = Paint()
      ..color = const Color.fromARGB(255, 8, 96, 24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ZigzagSquareLinePainter extends CustomPainter {
  final List<Offset> nodePositions;

  ZigzagSquareLinePainter(this.nodePositions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 96, 203, 133)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];

      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, start.dy);
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
