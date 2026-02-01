import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/widgets/block_coding_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:learnncode/screens/level/widgets/quiz_widget.dart';
import 'package:learnncode/screens/level/widgets/tts_widget.dart';
import 'package:learnncode/screens/level/screens/Result_page.dart';

class Level4 extends StatefulWidget {
  final Function(bool isCompleted, int score, int totalQuestions) onComplete;

  const Level4({super.key, required this.onComplete});

  @override
  State<Level4> createState() => _Level4State();
}

class _Level4State extends State<Level4> {
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
          'Bitwise operators in Python allow you to perform operations directly on the binary representations of numbers.'
    },
    {
      'type': 'text',
      'value':
          'The AND operator (&) compares two bits and returns 1 only if both bits are 1.'
    },
    {
      'type': 'text',
      'value':
          'The OR operator (|) compares two bits and returns 1 if at least one of the bits is 1.'
    },
    {
      'type': 'text',
      'value':
          'The XOR operator (^) returns 1 if the bits are different and 0 if they are the same.'
    },
    {
      'type': 'text',
      'value':
          'The NOT operator (~) simply flips each bit, turning 1s into 0s and 0s into 1s.'
    },
    {
      'type': 'text',
      'value':
          'The left shift operator (<<) shifts all bits in a number to the left by a specified number of positions.'
    },
    {
      'type': 'text',
      'value':
          'The right shift operator (>>) shifts all bits in a number to the right by a specified number of positions.'
    },
    {
      'type': 'text',
      'value':
          'Bitwise operations are very fast and are often used in low-level programming or performance-critical tasks.'
    },
    {
      'type': 'text',
      'value':
          'When you left shift a number, it multiplies the number by 2 for every shift position.'
    },
    {
      'type': 'text',
      'value':
          'When you right shift a number, it divides the number by 2 for every shift position (ignoring fractions).'
    },
    {
      'type': 'text',
      'value':
          'Binary numbers are made of only 0s and 1s, and bitwise operators manipulate these binary digits.'
    },
    {
      'type': 'text',
      'value':
          'For example, 5 & 3 is 1 because in binary 5 is 101 and 3 is 011, and only the last bit is common.'
    },
    {
      'type': 'text',
      'value':
          'Similarly, 5 | 3 gives 7 because any position with a 1 in either number results in a 1.'
    },
    {
      'type': 'text',
      'value':
          'The XOR operation is useful when you want to toggle bits — flipping only the different ones.'
    },
    {
      'type': 'text',
      'value':
          'The NOT (~) operator is a bit tricky because it flips all bits and changes the sign of the number in two\'s complement.'
    },
    {
      'type': 'text',
      'value':
          'Bitwise operations can be used to solve problems related to encryption, compression, and graphics.'
    },
    {
      'type': 'text',
      'value':
          'You can combine different bitwise operators in one expression for complex calculations.'
    },
    {
      'type': 'text',
      'value':
          'Understanding how bits work can help you write more efficient and faster programs.'
    },
    {
      'type': 'text',
      'value':
          'Although we usually work with decimal numbers, computers actually use binary numbers internally.'
    },
    {
      'type': 'text',
      'value':
          'Learning bitwise operations gives you a deeper understanding of how computers process data at the lowest level.'
    },
  ];

  // Quiz Content
  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': 'Which operator is used for bitwise AND in Python?',
      'options': ['&', '|', '^', '~'],
      'correctAnswerIndex': 0,
    },
    {
      'question': 'Which operator is used for bitwise OR in Python?',
      'options': ['&', '|', '~', '^'],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What does the bitwise XOR (^) operator do?',
      'options': [
        'Returns 1 if bits are the same',
        'Returns 0 if bits are different',
        'Returns 1 if bits are different',
        'Always returns 0'
      ],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What does the bitwise NOT (~) operator do?',
      'options': [
        'Adds two numbers',
        'Flips all the bits',
        'Shifts bits left',
        'Shifts bits right'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'Which operator shifts bits to the left?',
      'options': ['<<', '>>', '^', '~'],
      'correctAnswerIndex': 0,
    },
    {
      'question': 'What is the result of 5 & 3?',
      'options': ['5', '1', '7', '3'],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What happens when you left shift a number by 1 position?',
      'options': [
        'It divides by 2',
        'It multiplies by 2',
        'It remains the same',
        'It becomes zero'
      ],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What is the result of 6 >> 1?',
      'options': ['3', '6', '12', '2'],
      'correctAnswerIndex': 0,
    },
    {
      'question':
          'Bitwise operations work directly on what type of number system?',
      'options': ['Decimal', 'Octal', 'Binary', 'Hexadecimal'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'Why are bitwise operations important?',
      'options': [
        'They make programs slower',
        'They help in high-level design',
        'They allow low-level data manipulation and faster programs',
        'They are used only for decoration'
      ],
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
