import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/screens/result_page.dart';
import 'package:learnncode/screens/level/widgets/block_coding_widget.dart';
import 'package:learnncode/screens/level/widgets/quiz_widget.dart';
import 'package:learnncode/screens/level/widgets/tts_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:collection/collection.dart';

class DragAndDropWidget extends StatefulWidget {
  final String text;
  final List<String> options;
  final List<String> correctAnswers;
  final List<String> placeholders;
  final Function(bool) onValidate;

  const DragAndDropWidget({
    super.key,
    required this.text,
    required this.options,
    required this.correctAnswers,
    required this.placeholders,
    required this.onValidate,
  });

  @override
  State<DragAndDropWidget> createState() => _DragAndDropWidgetState();
}

class _DragAndDropWidgetState extends State<DragAndDropWidget> {
  late List<String?> userAnswers;

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
    bool isCorrect = ListEquality().equals(widget.correctAnswers, userAnswers);
    widget.onValidate(isCorrect);
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
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
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

class Level1 extends StatefulWidget {
  final Function(bool isCompleted, int score, int totalQuestions) onComplete;

  const Level1({super.key, required this.onComplete});

  @override
  State<Level1> createState() => _Level1AState();
}

class _Level1AState extends State<Level1> {
  int currentSection =
      0; // 0: TTS, 1: Quiz, 2: Drag-and-Drop, 3: Blockly, 4: Result
  int? quizSelectedAnswerIndex;
  int quizCurrentQuestion = 0;
  int quizScore = 0;
  bool _isTTSEnabled = true;
  bool _isLevelCompleted = false;
  double ttsProgress = 0.0; // Track TTS progress (0.0 to 1.0)
  bool dragAndDropCompleted = false;
  bool blocklyChallengeCompleted = false;

  // Total steps: TTS items + Quiz questions + Drag-and-Drop + Blockly challenge
  final int ttsTotalItems = 12; // Number of TTS items
  final int quizTotalItems = 5; // Number of quiz questions
  final int dragAndDropTotalItems = 1; // Drag-and-Drop challenge
  final int blocklyTotalItems = 1; // Blockly challenge
  final double ttsWeight = 0.25; // TTS contributes 25% of total progress
  final double quizWeight = 0.35; // Quiz contributes 35% of total progress
  final double dragAndDropWeight =
      0.15; // Drag-and-Drop contributes 15% of total progress
  final double blocklyWeight =
      0.25; // Blockly contributes 25% of total progress

  // TTS Content (Focused on Python, Data Types, and Variables)
  final List<Map<String, dynamic>> ttsContent = [
    {
      'type': 'text',
      'value':
          'Welcome to your first coding adventure! Today, we’re exploring Python, a fun and easy programming language.'
    },
    {
      'type': 'image',
      'value': 'assets/images/python_logo.png',
    },
    {
      'type': 'text',
      'value':
          'Programming is like giving instructions to a computer. It’s how we tell it what to do, step by step!'
    },
    {
      'type': 'animation',
      'value': {
        'asset': 'assets/lottie/Robot.json',
        'duration': 3000,
        'frames': {'start': 0, 'end': 100},
        'size': {'height': 300, 'width': 300}
      }
    },
    {
      'type': 'text',
      'value':
          'Python is great for beginners because its words are simple, almost like reading English.'
    },
    {
      'type': 'text',
      'value':
          'Let’s start with variables. Think of them as labeled boxes where you can store things, like numbers or names.'
    },
    {
      'type': 'animation',
      'value': {
        'asset': 'assets/lottie/variables.json',
        'duration': 2000,
        'frames': {'start': 0, 'end': 50},
        'size': {'height': 300, 'width': 300}
      }
    },
    {
      'type': 'text',
      'value':
          'For example, you can create a variable called “age” and put the number 10 in it. It’s like saying age = 10.'
    },
    {
      'type': 'text',
      'value':
          'You can change what’s in the box anytime. If it’s a birthday, you can update age to 11!'
    },
    {
      'type': 'text',
      'value':
          'Now, let’s talk about data types. These tell the computer what kind of thing is inside your box.'
    },
    {
      'type': 'animation',
      'value': {
        'asset': 'assets/lottie/datatypes.json',
        'duration': 2200,
        'frames': {'start': 0, 'end': 60},
        'size': {'height': 300, 'width': 300}
      }
    },
    {
      'type': 'text',
      'value':
          'There are numbers, like 5 or 3.14, called integers and floats. Words, like “hello”, are called strings.'
    },
    {
      'type': 'text',
      'value':
          'And there are true or false values, called booleans. They help the computer make decisions!'
    },
  ];

  // Quiz Content (Focused on Python, Data Types, and Variables)
  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': 'What is Python known for that makes it great for beginners?',
      'options': [
        'It uses complex words',
        'It has simple, English-like words',
        'It needs a lot of memory',
        'It’s hard to read'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What is a variable in programming?',
      'options': [
        'A button on the screen',
        'A box to store data like numbers or words',
        'A type of animation',
        'A sound effect'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'Which data type is used for whole numbers like 5 or 10?',
      'options': ['String', 'Float', 'Integer', 'Boolean'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What data type would you use for the word “hello”?',
      'options': ['Integer', 'String', 'Boolean', 'Float'],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'Which data type is used for true or false values?',
      'options': ['Integer', 'String', 'Boolean', 'Float'],
      'correctAnswerIndex': 2,
    },
  ];

  double get overallProgress {
    if (currentSection == 0) {
      // TTS section: Progress is based on ttsProgress (0.0 to 1.0)
      return ttsProgress * ttsWeight;
    } else if (currentSection == 1) {
      // Quiz section: TTS is complete (ttsWeight) + quiz progress
      double quizProgress = quizCurrentQuestion / quizTotalItems;
      return ttsWeight + (quizProgress * quizWeight);
    } else if (currentSection == 2) {
      // Drag-and-Drop section: TTS and Quiz are complete + Drag-and-Drop progress
      double dragAndDropProgress = dragAndDropCompleted ? 1.0 : 0.0;
      return ttsWeight + quizWeight + (dragAndDropProgress * dragAndDropWeight);
    } else if (currentSection == 3) {
      // Blockly section: TTS, Quiz, and Drag-and-Drop are complete + Blockly progress
      double blocklyProgress = blocklyChallengeCompleted ? 1.0 : 0.0;
      return ttsWeight +
          quizWeight +
          dragAndDropWeight +
          (blocklyProgress * blocklyWeight);
    } else {
      // Result section: Progress is complete
      return 1.0;
    }
  }

  void _nextSection() {
    if (currentSection == 0) {
      setState(() {
        currentSection = 1;
      });
    } else if (currentSection == 1 &&
        quizCurrentQuestion >= quizQuestions.length - 1 &&
        quizSelectedAnswerIndex != null) {
      setState(() {
        currentSection = 2; // Move to Drag-and-Drop section
      });
    } else if (currentSection == 2 && dragAndDropCompleted) {
      setState(() {
        currentSection = 3; // Move to Blockly section
      });
    } else if (currentSection == 3 && blocklyChallengeCompleted) {
      setState(() {
        currentSection = 4; // Move to Result section
        _isLevelCompleted = true;
        print(
            'Level completed! Score: $quizScore / ${quizQuestions.length + dragAndDropTotalItems + blocklyTotalItems}');
      });
    }
  }

  void _onQuizFinish(bool isCorrect) {
    print(
        'Quiz Finish: isCorrect=$isCorrect, Current Question=$quizCurrentQuestion, Score=$quizScore');
    if (quizCurrentQuestion < quizQuestions.length - 1) {
      setState(() {
        if (isCorrect) {
          quizScore++;
          print('Correct answer! New Score: $quizScore');
        } else {
          print('Wrong answer! Score remains: $quizScore');
        }
        quizCurrentQuestion++;
        quizSelectedAnswerIndex = null;
      });
    } else {
      setState(() {
        if (isCorrect) {
          quizScore++;
          print('Correct answer (last question)! New Score: $quizScore');
        } else {
          print('Wrong answer (last question)! Score remains: $quizScore');
        }
        _nextSection();
      });
    }
  }

  void _onDragAndDropCompleted(bool isCorrect) {
    setState(() {
      if (isCorrect) {
        quizScore++; // Add to score for completing the Drag-and-Drop challenge
        dragAndDropCompleted = true;
        print('Drag-and-Drop challenge completed! New Score: $quizScore');
        _nextSection();
      }
    });
  }

  void _onBlocklyChallengeCompleted(bool isCorrect) {
    setState(() {
      if (isCorrect) {
        quizScore++; // Add to score for completing the Blockly challenge
        blocklyChallengeCompleted = true;
        print('Blockly challenge completed! New Score: $quizScore');
        _nextSection();
      }
    });
  }

  void _toggleTTS() {
    setState(() {
      _isTTSEnabled = !_isTTSEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    print(
                        'Exiting level. Score: $quizScore, Total Questions: ${quizQuestions.length + dragAndDropTotalItems + blocklyTotalItems}');
                    widget.onComplete(
                        _isLevelCompleted,
                        quizScore,
                        quizQuestions.length +
                            dragAndDropTotalItems +
                            blocklyTotalItems);
                  },
                  child: const Icon(Icons.close, color: Colors.black, size: 24),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleTTS,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTTSEnabled ? Colors.green : Colors.red,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CC00)),
            minHeight: 8.0,
          ),
          Expanded(
            child: IndexedStack(
              index: currentSection,
              children: [
                TTSWidget(
                  content: ttsContent,
                  paragraphStyle: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  progressColor: const Color(0xFF00CC00),
                  onContentCompleted: _nextSection,
                  isTTSEnabled: _isTTSEnabled,
                  showMic: false,
                  onProgressUpdate: (progress) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          ttsProgress = progress;
                          print('TTS Progress: ${ttsProgress * 100}%');
                        });
                      }
                    });
                  },
                ),
                QuizWidget(
                  question: quizQuestions[quizCurrentQuestion]['question'],
                  options: List<String>.from(
                      quizQuestions[quizCurrentQuestion]['options']),
                  correctAnswerIndex: quizQuestions[quizCurrentQuestion]
                      ['correctAnswerIndex'],
                  selectedAnswerIndex: quizSelectedAnswerIndex,
                  onAnswerSelected: (index) {
                    print('Answer selected: $index');
                    setState(() {
                      quizSelectedAnswerIndex = index;
                    });
                  },
                  onFinish: _onQuizFinish,
                  progress: quizCurrentQuestion / quizQuestions.length,
                ),
                DragAndDropWidget(
                  text:
                      'Assign the value 15 to a variable named ___ using the ___ data type.',
                  options: ['age', 'string', 'integer', '15'],
                  correctAnswers: ['age', 'integer'],
                  placeholders: ['___', '___'],
                  onValidate: _onDragAndDropCompleted,
                ),
                BlocklyCodingWidget(
                  challengeDescription:
                      'Write a Python program to add 5 and 3 and print the result. The output should be "8".',
                  expectedOutput: '8',
                  onChallengeCompleted: _onBlocklyChallengeCompleted,
                ),
                ResultScreen(
                  score: quizScore,
                  totalQuestions: quizQuestions.length +
                      dragAndDropTotalItems +
                      blocklyTotalItems,
                  onBack: () {
                    print(
                        'Finish pressed. Score: $quizScore, Total Questions: ${quizQuestions.length + dragAndDropTotalItems + blocklyTotalItems}');
                    widget.onComplete(
                        true,
                        quizScore,
                        quizQuestions.length +
                            dragAndDropTotalItems +
                            blocklyTotalItems);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
