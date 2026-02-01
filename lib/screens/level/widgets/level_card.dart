import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/screens/level_navigation.dart';

class LevelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String status;
  final String lessons;
  final int progressPercentage;
  final bool completed;
  final bool locked;
  final int unitIndex; // Added unitIndex parameter
  final Function(String, int)
      onLevelCompleted; // Added onLevelCompleted callback

  const LevelCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.status,
    required this.lessons,
    required this.progressPercentage,
    this.completed = false,
    this.locked = false,
    required this.unitIndex, // Make unitIndex required
    required this.onLevelCompleted, // Make onLevelCompleted required
  });

  @override
  Widget build(BuildContext context) {
    // Screen size
    final screenWidth = MediaQuery.of(context).size.width;

    // Wrap the card with InkWell for tap detection
    return InkWell(
      onTap: locked
          ? null // Disable tap if the level is locked
          : () {
              // Navigate to ZigzagSquareLinesScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LevelDesign(
                    unitIndex: unitIndex, // Pass unitIndex
                    onLevelCompleted: onLevelCompleted, // Pass callback
                  ),
                ),
              );
            },
      child: Card(
        elevation: locked ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: locked ? Colors.grey.shade200 : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045, // Dynamic font size
                      fontWeight: FontWeight.bold,
                      color: locked
                          ? Colors.grey
                          : completed
                              ? Colors.green
                              : const Color(0xFF6C4AB6),
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    decoration: BoxDecoration(
                      color: locked
                          ? Colors.grey.shade300
                          : completed
                              ? Colors.green.shade100
                              : const Color(0xFF6C4AB6),
                      borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    ),
                    child: Center(
                      child: locked
                          ? const Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 30,
                            )
                          : completed
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                )
                              : Text(
                                  '$progressPercentage%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // Dynamic font size
                  fontWeight: FontWeight.w600,
                  color: locked ? Colors.grey : Colors.black,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.035, // Dynamic font size
                  color: locked ? Colors.grey.shade600 : Colors.grey.shade700,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035, // Dynamic font size
                      color: locked
                          ? Colors.grey
                          : completed
                              ? Colors.green
                              : const Color(0xFF6C4AB6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lessons,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035, // Dynamic font size
                      color: locked ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
