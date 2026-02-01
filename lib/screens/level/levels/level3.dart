import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/widgets/block_coding_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:learnncode/screens/level/widgets/quiz_widget.dart';
import 'package:learnncode/screens/level/widgets/tts_widget.dart';
import 'package:learnncode/screens/level/screens/Result_page.dart';

class Level3 extends StatefulWidget {
  final Function(bool isCompleted, int score, int totalQuestions) onComplete;

  const Level3({super.key, required this.onComplete});

  @override
  State<Level3> createState() => _Level3State();
}

class _Level3State extends State<Level3> {
  int currentSection = 0; // 0: TTS, 1: Quiz, 2: Blockly, 3: Result
  int? quizSelectedAnswerIndex;
  int quizCurrentQuestion = 0;
  int quizScore = 0;
  bool _isTTSEnabled = true;
  bool _isLevelCompleted = false;
  double ttsProgress = 0.0; // Track TTS progress (0.0 to 1.0)
  bool blocklyChallengeCompleted = false;

  // Total steps: TTS items + Quiz questions + Blockly challenge
  final int ttsTotalItems = 27; // Number of TTS items
  final int quizTotalItems = 5; // Number of quiz questions
  final int blocklyTotalItems = 1; // Blockly challenge
  final double ttsWeight = 1 / 6; // TTS contributes 1/6 of total progress
  final double quizWeight = 4 / 6; // Quiz contributes 4/6 of total progress
  final double blocklyWeight =
      1 / 6; // Blockly contributes 1/6 of total progress

  // TTS Content
  final List<Map<String, dynamic>> ttsContent = [
    {
      'type': 'text',
      'value':
          'Python allows you to perform basic arithmetic operations easily on numbers.'
    },
    {
      'type': 'text',
      'value':
          'Addition (+) is used to add two numbers together, like 5 + 3 = 8.'
    },
    {
      'type': 'text',
      'value':
          'Subtraction (-) helps you find the difference between two numbers, like 10 - 4 = 6.'
    },
    {
      'type': 'text',
      'value':
          'Multiplication (*) allows you to multiply two numbers, like 7 * 6 = 42.'
    },
    {
      'type': 'text',
      'value':
          'Division (/) divides one number by another and always gives a float result, like 8 / 2 = 4.0.'
    },
    {
      'type': 'text',
      'value':
          'The modulus operator (%) gives the remainder of a division, like 10 % 3 = 1.'
    },
    {
      'type': 'text',
      'value':
          'Exponentiation (**) raises a number to the power of another, like 2 ** 3 = 8.'
    },
    {
      'type': 'text',
      'value':
          'Floor division (//) divides numbers but rounds the result down to the nearest whole number.'
    },
    {
      'type': 'text',
      'value':
          'Addition and subtraction are evaluated from left to right in an expression.'
    },
    {
      'type': 'text',
      'value':
          'Python follows the normal mathematics rules called "operator precedence" (like BODMAS).'
    },
    {
      'type': 'text',
      'value':
          'You can group operations using parentheses () to control the order.'
    },
    {
      'type': 'text',
      'value':
          'Multiplication and division are performed before addition and subtraction.'
    },
    {
      'type': 'text',
      'value':
          'The result of a division is always a floating-point number, even if it looks like a whole number.'
    },
    {
      'type': 'text',
      'value':
          'The modulus operator is very useful when you want to check if a number is even or odd.'
    },
    {
      'type': 'text',
      'value':
          'Exponentiation can be used for powers like squaring, cubing, and more complex calculations.'
    },
    {
      'type': 'text',
      'value':
          'Floor division is very useful when you want an integer result without any decimal part.'
    },
    {
      'type': 'text',
      'value':
          'Mixing integers and floats in operations will usually result in a float output.'
    },
    {
      'type': 'text',
      'value':
          'You can use arithmetic operations not just with numbers, but sometimes with variables too!'
    },
    {
      'type': 'text',
      'value':
          'Python evaluates expressions carefully, so it’s important to know which operator comes first.'
    },
    {
      'type': 'text',
      'value':
          'Practicing simple arithmetic operations helps you build strong foundations for programming logic.'
    },
  ];

  // Quiz Content
  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': 'Which operator is used for addition in Python?',
      'options': ['-', '*', '+', '/'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What is the result of 10 - 4?',
      'options': ['14', '6', '7', '5'],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'Which operator is used to find the remainder of a division?',
      'options': ['/', '//', '%', '**'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What does the ** operator do in Python?',
      'options': [
        'Divides two numbers',
        'Adds two numbers',
        'Finds the remainder',
        'Raises a number to a power'
      ],
      'correctAnswerIndex': 3,
    },
    {
      'question': 'What is the output of 5 * 6?',
      'options': ['30', '11', '56', '12'],
      'correctAnswerIndex': 0,
    },
    {
      'question':
          'Which operator gives a floating-point result even when numbers divide evenly?',
      'options': ['/', '//', '+', '-'],
      'correctAnswerIndex': 0,
    },
    {
      'question': 'What is the result of 9 // 2?',
      'options': ['4.5', '4', '5', '5.0'],
      'correctAnswerIndex': 2,
    },
    {
      'question':
          'Which operation is performed first according to operator precedence?',
      'options': [
        'Addition',
        'Multiplication',
        'Subtraction',
        'None, Python reads left to right'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question':
          'How do you ensure certain operations happen first in Python?',
      'options': [
        'Use a calculator',
        'Use parentheses ()',
        'Write operations backward',
        'There is no way'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What is the output of 2 ** 4?',
      'options': ['6', '16', '8', '24'],
      'correctAnswerIndex': 1,
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
      // Blockly section: TTS and Quiz are complete + Blockly progress
      double blocklyProgress = blocklyChallengeCompleted ? 1.0 : 0.0;
      return ttsWeight + quizWeight + (blocklyProgress * blocklyWeight);
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
        currentSection = 2; // Move to Blockly section
      });
    } else if (currentSection == 2 && blocklyChallengeCompleted) {
      setState(() {
        currentSection = 3; // Move to Result section
        _isLevelCompleted = true;
        print(
            'Level completed! Score: $quizScore / ${quizQuestions.length + blocklyTotalItems}');
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

  void _toggleTTS() {
    setState(() {
      _isTTSEnabled = !_isTTSEnabled;
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
                        'Exiting level. Score: $quizScore, Total Questions: ${quizQuestions.length + blocklyTotalItems}');
                    widget.onComplete(_isLevelCompleted, quizScore,
                        quizQuestions.length + blocklyTotalItems);
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
                    child: Center(
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
                BlocklyCodingWidget(
                  challengeDescription:
                      'Write a Python program to add 5 and 3 and print the result. The output should be "8".',
                  expectedOutput: '8',
                  onChallengeCompleted: _onBlocklyChallengeCompleted,
                ),
                ResultScreen(
                  score: quizScore,
                  totalQuestions: quizQuestions.length + blocklyTotalItems,
                  onBack: () {
                    print(
                        'Finish pressed. Score: $quizScore, Total Questions: ${quizQuestions.length + blocklyTotalItems}');
                    widget.onComplete(true, quizScore,
                        quizQuestions.length + blocklyTotalItems);
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
