import 'package:flutter/material.dart';
import 'package:learnncode/screens/level/widgets/block_coding_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:learnncode/screens/level/widgets/quiz_widget.dart';
import 'package:learnncode/screens/level/widgets/tts_widget.dart';
import 'package:learnncode/screens/level/screens/Result_page.dart';

class Level2 extends StatefulWidget {
  final Function(bool isCompleted, int score, int totalQuestions) onComplete;

  const Level2({super.key, required this.onComplete});

  @override
  State<Level2> createState() => _Level2State();
}

class _Level2State extends State<Level2> {
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
          'In Python, a data type tells us what kind of value a variable holds, like a number, text, or a list of items.'
    },
    {
      'type': 'text',
      'value':
          'Integers in Python represent whole numbers, such as 5, -10, or 2025, and are written without any decimal point.'
    },
    {
      'type': 'text',
      'value':
          'Floating-point numbers (floats) are numbers with a decimal point, like 3.14 or -0.99.'
    },
    {
      'type': 'text',
      'value':
          'Strings in Python are sequences of characters, enclosed in single or double quotes, like "Hello" or \'Python\'.'
    },
    {
      'type': 'text',
      'value':
          'Booleans are a special data type with only two possible values: True or False, useful for decision-making.'
    },
    {
      'type': 'text',
      'value':
          'A list is a collection of items, like [1, 2, 3, 4], where you can store multiple values in a single variable.'
    },
    {
      'type': 'text',
      'value':
          'Tuples are like lists but cannot be changed once created; they are written using parentheses like (1, 2, 3).'
    },
    {
      'type': 'text',
      'value':
          'Dictionaries store data in key-value pairs, like {"name": "Alice", "age": 25}, allowing fast lookups.'
    },
    {
      'type': 'text',
      'value':
          'Python automatically assigns the correct data type when you assign a value, making coding quicker and easier.'
    },
    {
      'type': 'text',
      'value':
          'Understanding data types is essential because they affect what operations you can perform on the values.'
    },
    {
      'type': 'text',
      'value':
          'Sets are another collection type in Python that stores unique elements without any duplicates.'
    },
    {
      'type': 'text',
      'value':
          'A string in Python is basically an array of characters, and you can access characters by their index.'
    },
    {
      'type': 'text',
      'value':
          'Boolean values are often the result of comparison operations like ==, !=, >, or <.'
    },
    {
      'type': 'text',
      'value':
          'Using correct data types in Python improves the performance and readability of your code.'
    },
    {
      'type': 'text',
      'value':
          'Variables in Python do not need explicit declaration of data types; they are assigned automatically.'
    }
  ];

  // Quiz Content
  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': 'What is a data type in Python?',
      'options': [
        'A type of error',
        'A way to store large programs',
        'It tells what kind of value a variable holds',
        'A type of comment'
      ],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'Which of the following is an integer in Python?',
      'options': ['3.14', '-7', '"123"', 'True'],
      'correctAnswerIndex': 1,
    },
    {
      'question': 'What symbol is used to define a tuple in Python?',
      'options': [
        'Square brackets []',
        'Curly braces {}',
        'Parentheses ()',
        'Angle brackets <>'
      ],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'Which data type is used to store True or False values?',
      'options': ['String', 'Boolean', 'Float', 'List'],
      'correctAnswerIndex': 1,
    },
    {
      'question':
          'Which function is used to check the type of a variable in Python?',
      'options': ['kind()', 'typeof()', 'type()', 'check()'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'Which collection type only stores unique items?',
      'options': ['List', 'Tuple', 'Set', 'Dictionary'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'How do you define a dictionary in Python?',
      'options': [
        'Using parentheses ()',
        'Using square brackets []',
        'Using curly braces {}',
        'Using angle brackets <>'
      ],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What is the result of type(3.5) in Python?',
      'options': ['int', 'str', 'float', 'bool'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'Which of these data types is immutable?',
      'options': ['List', 'Set', 'Tuple', 'Dictionary'],
      'correctAnswerIndex': 2,
    },
    {
      'question': 'What happens if you try to change a value in a tuple?',
      'options': [
        'It changes successfully',
        'An error occurs',
        'It gets removed',
        'It turns into a list'
      ],
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
