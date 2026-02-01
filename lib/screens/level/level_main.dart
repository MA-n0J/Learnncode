import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learnncode/screens/community/screens/community_page.dart';
import 'package:learnncode/screens/level/code_editor/code_editor.dart';
import 'package:learnncode/screens/level/screens/level_navigation.dart';
import 'package:learnncode/screens/level/widgets/level_card.dart';
import 'package:provider/provider.dart';
import 'package:learnncode/providers/state_manager.dart';
import 'package:learnncode/screens/leaderboard/leaderboard.dart';
import 'package:learnncode/screens/profile/profile.dart';
import 'package:learnncode/screens/onboarding/onboarding_screen.dart';

class LevelDesignScreen extends StatefulWidget {
  const LevelDesignScreen({super.key, this.onItemTapped, this.selectedIndex});

  final Function(int)? onItemTapped;
  final int? selectedIndex;

  @override
  _LevelDesignScreenState createState() => _LevelDesignScreenState();
}

class _LevelDesignScreenState extends State<LevelDesignScreen> {
  int _selectedIndex = 0;
  bool _isDisposing = false;

  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    print('LevelDesignScreen: initState called');
    _selectedIndex = widget.selectedIndex ?? 0;
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated, redirecting to OnboardingScreen');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    print('LevelDesignScreen: dispose called');
    _isDisposing = true;
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      print('LevelDesignScreen: Same index $index selected, ignoring');
      return;
    }
    print('LevelDesignScreen: Navigating to index $index');
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToLevelDesign(int unitIndex) {
    print(
        'LevelDesignScreen: Navigating to LevelDesign for unit ${unitIndex + 1}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelDesign(
          unitIndex: unitIndex,
          onLevelCompleted: (String unitId, int level) async {
            print(
                'LevelDesignScreen: onLevelCompleted callback triggered for unitId=$unitId, level=$level');
            await _onLevelCompleted(unitId, level);
          },
        ),
      ),
    );
  }

  void _navigateToPythonEditor() {
    print('LevelDesignScreen: Navigating to PythonEditorScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PythonEditorScreen()),
    );
  }

  Future<String?> _getParentUid(String learnerUid) async {
    print('LevelDesignScreen: Fetching parent UID for learnerUid=$learnerUid');
    final learnerDoc =
        await _firestore.collection('users').doc(learnerUid).get();
    if (!learnerDoc.exists) {
      print('LevelDesignScreen: Learner document does not exist');
      return null;
    }

    final parentEmail = learnerDoc.data()?['parentEmail']?.toLowerCase();
    if (parentEmail == null) {
      print('LevelDesignScreen: parentEmail not found in learner document');
      return null;
    }

    print('LevelDesignScreen: Found parentEmail=$parentEmail');

    final parentQuery = await _firestore
        .collection('parents')
        .where('email', isEqualTo: parentEmail)
        .limit(1)
        .get();

    if (parentQuery.docs.isEmpty) {
      print('LevelDesignScreen: No parent found with email=$parentEmail');
      final parentByLearnerQuery = await _firestore
          .collection('parents')
          .where('linkedLearnerIds', arrayContains: learnerUid)
          .limit(1)
          .get();

      if (parentByLearnerQuery.docs.isEmpty) {
        print(
            'LevelDesignScreen: No parent found linked to learnerUid=$learnerUid');
        return null;
      }

      final parentDoc = parentByLearnerQuery.docs.first;
      final parentUid = parentDoc.id;
      final actualParentEmail = parentDoc.data()['email'];
      print(
          'LevelDesignScreen: Found parent via linkedLearnerIds: UID=$parentUid, email=$actualParentEmail');
      print(
          'LevelDesignScreen: Mismatch detected - learner parentEmail=$parentEmail, actual parent email=$actualParentEmail');
      await _firestore.collection('users').doc(learnerUid).update({
        'parentEmail': actualParentEmail,
      });
      print(
          'LevelDesignScreen: Updated learner parentEmail to $actualParentEmail');
      return parentUid;
    }

    final parentUid = parentQuery.docs.first.id;
    print('LevelDesignScreen: Found parentUid=$parentUid');
    return parentUid;
  }

  Future<void> sendNotificationToParent(
      String parentUid, String message) async {
    print('LevelDesignScreen: Sending notification to parentUid=$parentUid');
    const String onesignalAppId = "95ecc7de-3418-4564-b508-d913ac44700d";
    const String onesignalApiKey =
        "os_v2_app_sxwmpxrudbcwjnii3ej2yrdqbxuginsptzvukmn7o5j3sfiflhfykbzkz4aa2cln7yyql5f2la4g4gel5bakssgc5bzc66z52ymj5vi";

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $onesignalApiKey',
    };

    final body = jsonEncode({
      'app_id': onesignalAppId,
      'include_external_user_ids': [parentUid],
      'contents': {'en': message},
      'headings': {'en': 'Learner Progress Update'},
    });

    print('LevelDesignScreen: Sending OneSignal request: $body');
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print(
            'LevelDesignScreen: Notification sent successfully: ${response.body}');
      } else {
        print(
            'LevelDesignScreen: Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('LevelDesignScreen: Error sending notification: $e');
    }
  }

  Future<void> _onLevelCompleted(String unitId, int level) async {
    print(
        'LevelDesignScreen: _onLevelCompleted called with unitId=$unitId, level=$level');
    final user = _auth.currentUser;
    if (user == null) {
      print('LevelDesignScreen: No user logged in');
      return;
    }

    final learnerUid = user.uid;

    print('LevelDesignScreen: Updating Realtime Database for user=$learnerUid');
    await _database.child('users/$learnerUid/unitProgress').update({
      'unit${unitId}_level$level': true,
    });

    final snapshot = await _database.child('users/$learnerUid').get();
    final data = snapshot.value as Map<dynamic, dynamic>;
    int currentUnlockedLevels = data['unlockedLevels'] ?? 1;
    if (level + 1 > currentUnlockedLevels) {
      print('LevelDesignScreen: Updating unlockedLevels to ${level + 1}');
      await _database.child('users/$learnerUid').update({
        'unlockedLevels': level + 1,
      });
    }

    final parentUid = await _getParentUid(learnerUid);
    if (parentUid == null) {
      print('LevelDesignScreen: Parent not found for learner: $learnerUid');
      return;
    }

    final message = "Your learner has completed Unit $unitId, Level $level!";
    await sendNotificationToParent(parentUid, message);
  }

  Widget _buildLevelDesignScreen(BuildContext context, AppState appState) {
    final List<int> completedLevelsPerUnit = List.filled(10, 0);
    int totalCompletedLevels = 0;

    for (int unit = 1; unit <= 10; unit++) {
      for (int level = 1; level <= 4; level++) {
        final unitId = 'unit${unit}_level$level';
        if (appState.unitProgress[unitId] ?? false) {
          completedLevelsPerUnit[unit - 1]++;
          totalCompletedLevels++;
        }
      }
    }

    final completionPercentage = (totalCompletedLevels / (10 * 4)) * 100;

    print(
        'LevelDesignScreen: Building UI with xp=${appState.xp}, completionPercentage=$completionPercentage');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    final levels = List.generate(
      10,
      (unitIndex) {
        int completedLevelsInUnit = completedLevelsPerUnit[unitIndex];
        bool isCompleted = completedLevelsInUnit == 4;
        bool isLocked =
            unitIndex > 0 && completedLevelsPerUnit[unitIndex - 1] < 4;

        return GestureDetector(
          onTap: isLocked
              ? null
              : () {
                  print('LevelDesignScreen: Tapped Unit ${unitIndex + 1}');
                  _navigateToLevelDesign(unitIndex);
                },
          child: LevelCard(
            unitIndex: unitIndex,
            onLevelCompleted: _onLevelCompleted,
            title: 'Unit ${unitIndex + 1}',
            subtitle: unitIndex == 0
                ? 'Python Introduction'
                : unitIndex == 1
                    ? 'Conditional Statements'
                    : unitIndex == 2
                        ? 'Loops'
                        : unitIndex == 3
                            ? 'Lists'
                            : unitIndex == 4
                                ? 'Tuples'
                                : unitIndex == 5
                                    ? 'Dictionaries'
                                    : unitIndex == 6
                                        ? 'String Operations'
                                        : unitIndex == 7
                                            ? 'Functions'
                                            : unitIndex == 8
                                                ? 'Import'
                                                : unitIndex == 9
                                                    ? 'OOPS Concepts'
                                                    : 'Advanced Unit ${unitIndex + 1}',
            description: unitIndex == 0
                ? 'Learn the basic concepts and foundations'
                : unitIndex == 1
                    ? 'Master decision-making with if-else statements for program control.'
                    : unitIndex == 2
                        ? 'Efficiently repeat code using for and while loops.'
                        : unitIndex == 3
                            ? 'Manage mutable, ordered collections with Python lists.'
                            : unitIndex == 4
                                ? 'Explore immutable sequence types'
                                : unitIndex == 5
                                    ? 'Understand key-value pair structures'
                                    : unitIndex == 6
                                        ? 'Master text manipulation techniques'
                                        : unitIndex == 7
                                            ? 'Learn to create reusable code blocks'
                                            : unitIndex == 8
                                                ? 'Discover module integration'
                                                : unitIndex == 9
                                                    ? 'Grasp object-oriented programming'
                                                    : 'Continue your learning journey',
            status: isLocked
                ? 'Locked'
                : isCompleted
                    ? 'Completed!'
                    : 'In Progress',
            lessons: '$completedLevelsInUnit/4 Levels',
            progressPercentage: (completedLevelsInUnit / 4 * 100).toInt(),
            completed: isCompleted,
            locked: isLocked,
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.7),
                Colors.teal.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${appState.streak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${appState.xp} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
            onPressed: () {
              print('LevelDesignScreen: Notifications tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped!')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.teal.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: isSmallScreen
              ? ListView.builder(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  cacheExtent: screenHeight * 2,
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _AnimatedLevelCard(
                        index: index,
                        child: RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade300.withOpacity(0.5),
                              ),
                            ),
                            child: levels[index],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  cacheExtent: screenHeight * 2,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMediumScreen ? 2 : 3,
                    crossAxisSpacing: screenWidth * 0.02,
                    mainAxisSpacing: screenHeight * 0.02,
                    childAspectRatio: isMediumScreen ? 1.5 : 1.8,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    return _AnimatedLevelCard(
                      index: index,
                      child: RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade300.withOpacity(0.5),
                            ),
                          ),
                          child: levels[index],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPythonEditor,
        backgroundColor: Colors.green[700],
        child: const Icon(
          Icons.code,
          color: Colors.white,
        ),
        tooltip: 'Practice Coding',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposing) {
      print('LevelDesignScreen: Skipping build due to disposal');
      return const SizedBox.shrink();
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final pages = [
          _buildLevelDesignScreen(context, appState),
          LeaderboardPage(
            onItemTapped: _onItemTapped,
            selectedIndex: _selectedIndex,
          ),
          ProfilePage(
            onItemTapped: _onItemTapped,
            selectedIndex: _selectedIndex,
          ),
          CommunityPage(
            onItemTapped: _onItemTapped,
            selectedIndex: _selectedIndex,
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: const Color(0xFF58CC02),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                label: 'Community',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedLevelCard extends StatelessWidget {
  final Widget child;
  final int index;

  const _AnimatedLevelCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 30)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
