import 'package:flutter/material.dart';

class QuizWidget extends StatelessWidget {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int? selectedAnswerIndex;
  final Function(int) onAnswerSelected;
  final Function(bool) onFinish;
  final double progress;

  const QuizWidget({
    super.key,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.selectedAnswerIndex,
    required this.onAnswerSelected,
    required this.onFinish,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: selectedAnswerIndex == null
                              ? () {
                                  print('Selected answer index: $index');
                                  onAnswerSelected(index);
                                }
                              : null,
                          child: AnswerCard(
                            currentIndex: index,
                            question: options[index],
                            isSelected: selectedAnswerIndex == index,
                            selectedAnswerIndex: selectedAnswerIndex,
                            correctAnswerIndex: correctAnswerIndex,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: RectangularButton(
                      onPressed: selectedAnswerIndex != null
                          ? () {
                              bool isCorrect =
                                  selectedAnswerIndex == correctAnswerIndex;
                              print(
                                  'Submitting: Selected=$selectedAnswerIndex, Correct=$correctAnswerIndex, isCorrect=$isCorrect');
                              onFinish(isCorrect);
                            }
                          : null,
                      label: 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnswerCard extends StatelessWidget {
  final int currentIndex;
  final String question;
  final bool isSelected;
  final int? selectedAnswerIndex;
  final int correctAnswerIndex;

  const AnswerCard({
    required this.currentIndex,
    required this.question,
    required this.isSelected,
    required this.selectedAnswerIndex,
    required this.correctAnswerIndex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Icon? answerIcon;
    Color borderColor = Colors.grey;

    if (selectedAnswerIndex != null) {
      if (currentIndex == correctAnswerIndex) {
        backgroundColor = Colors.lightGreenAccent.withOpacity(0.5);
        borderColor = Colors.green;
        answerIcon =
            const Icon(Icons.check_circle, color: Colors.green, size: 30);
      } else if (currentIndex == selectedAnswerIndex) {
        backgroundColor = Colors.redAccent.withOpacity(0.5);
        borderColor = Colors.red;
        answerIcon = const Icon(Icons.cancel, color: Colors.red, size: 30);
      }
    } else if (isSelected) {
      backgroundColor = Colors.yellowAccent.withOpacity(0.5);
      borderColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(
          color: borderColor,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (answerIcon != null) answerIcon,
        ],
      ),
    );
  }
}

class RectangularButton extends StatelessWidget {
  const RectangularButton({
    Key? key,
    required this.onPressed,
    required this.label,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.blue : Colors.grey[300],
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onPressed != null ? Colors.white : Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
