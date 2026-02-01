import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class DragAndDropWidget extends StatefulWidget {
  final String text;
  final List<String> options;
  final List<String> correctAnswers;
  final List<String> placeholders;
  final Function(bool) onValidate;
  final Function() onNext; // Added callback for "Next" button

  const DragAndDropWidget({
    super.key,
    required this.text,
    required this.options,
    required this.correctAnswers,
    required this.placeholders,
    required this.onValidate,
    required this.onNext,
  });

  @override
  State<DragAndDropWidget> createState() => _DragAndDropWidgetState();
}

class _DragAndDropWidgetState extends State<DragAndDropWidget> {
  late List<String?> userAnswers;
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    userAnswers =
        List<String?>.filled(widget.placeholders.length, null, growable: false);
  }

  void selectAnswer(String option) {
    setState(() {
      if (!userAnswers.contains(option)) {
        int index = userAnswers.indexWhere((ans) => ans == null);
        if (index != -1) {
          userAnswers[index] = option;
        }
      }
    });
  }

  void removeAnswer(int index) {
    setState(() {
      userAnswers[index] = null;
    });
  }

  void checkAnswers() {
    setState(() {
      isCorrect = ListEquality().equals(widget.correctAnswers, userAnswers);
      showFeedback = true;
      widget.onValidate(isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> textSpans = [];
    String remainingText = widget.text;

    for (int i = 0; i < widget.placeholders.length; i++) {
      List<String> parts = remainingText.split(widget.placeholders[i]);
      if (parts.isNotEmpty) {
        textSpans.add(TextSpan(
          text: parts[0],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ));
        remainingText = parts.length > 1
            ? parts.sublist(1).join(widget.placeholders[i])
            : '';
        textSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => removeAnswer(i),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                userAnswers[i] ?? widget.placeholders[i],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ));
      }
    }
    if (remainingText.isNotEmpty) {
      textSpans.add(TextSpan(
        text: remainingText,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                  child: RichText(
                    text: TextSpan(
                      children: textSpans,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.options.map((option) {
                    return GestureDetector(
                      onTap: () => selectAnswer(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: userAnswers.contains(option)
                              ? Colors.grey.shade400
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                if (showFeedback)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            isCorrect ? 'Correct!' : 'Incorrect!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          if (!isCorrect) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Correct answers: ${widget.correctAnswers.join(", ")}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: showFeedback
                ? ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: userAnswers.where((a) => a != null).length ==
                            widget.placeholders.length
                        ? checkAnswers
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Check Answer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
