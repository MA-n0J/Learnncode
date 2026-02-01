import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_database/firebase_database.dart';
import 'package:learnncode/screens/leaderboard/user_followers.dart';
import 'package:learnncode/screens/leaderboard/user_following.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String name;
  final String avatarUrl;
  final int xp;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.xp,
  });

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isFollowing = false;
  Map<String, int> _dailyXP = {};
  StreamSubscription<DatabaseEvent>? _dailyXPListener;
  String? _errorMessage;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _checkOwnProfile();
    _checkFollowStatus();
    _loadDailyXP();
  }

  @override
  void dispose() {
    _dailyXPListener?.cancel();
    super.dispose();
  }

  void _checkOwnProfile() {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == widget.userId) {
      setState(() {
        _isOwnProfile = true;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'You must be logged in to follow users.';
      });
      return;
    }

    final currentUserId = currentUser.uid;
    final snapshot = await _database
        .child('users/${widget.userId}/followers/$currentUserId')
        .get();

    if (snapshot.exists) {
      setState(() {
        _isFollowing = true;
      });
    } else {
      setState(() {
        _isFollowing = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to follow users')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    try {
      if (_isFollowing) {
        await _database
            .child('users/${widget.userId}/followers/$currentUserId')
            .remove();
        await _database
            .child('users/$currentUserId/following/${widget.userId}')
            .remove();
      } else {
        await _database
            .child('users/${widget.userId}/followers/$currentUserId')
            .set({
          'followedAt': DateTime.now().toIso8601String(),
        });
        await _database
            .child('users/$currentUserId/following/${widget.userId}')
            .set({
          'followedAt': DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing
              ? 'Followed ${widget.name}'
              : 'Unfollowed ${widget.name}'),
          backgroundColor: _isFollowing ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }

  Future<void> _loadDailyXP() async {
    final dailyXPRef = _database.child('users/${widget.userId}/dailyXP');

    _dailyXPListener = dailyXPRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            _dailyXP =
                data.map((key, value) => MapEntry(key as String, value as int));
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _dailyXP = {};
          });
        }
      }
    }, onError: (error) {
      print('Error loading dailyXP: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load daily XP: $error';
        });
      }
    });
  }

  void _navigateToFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => UserFollowersPage(userId: widget.userId)),
    );
  }

  void _navigateToFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => UserFollowingPage(userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF6C4AB6),
              title: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.05,
              ),
              color: Colors.grey[100],
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.avatarUrl.isNotEmpty
                        ? NetworkImage(widget.avatarUrl)
                        : const AssetImage('assets/images/default.png')
                            as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: screenHeight * 0.025,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Joined March 2024",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _navigateToFollowing,
                        child: Text(
                          "15 Following",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: screenHeight * 0.02,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      GestureDetector(
                        onTap: _navigateToFollowers,
                        child: Text(
                          "14 Followers",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: screenHeight * 0.02,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (!_isOwnProfile)
                    ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.grey
                            : const Color(0xFF6C4AB6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      child: Text(
                        _isFollowing ? 'Unfollow' : 'Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Statistics",
                    style: TextStyle(
                      fontSize: screenHeight * 0.022,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C4AB6), Color(0xFF8D65D1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(screenHeight * 0.02),
                    child: Column(
                      children: [
                        Text(
                          "XP Progress (Last 7 Days)",
                          style: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          height: screenHeight * 0.3,
                          child: _errorMessage != null
                              ? Center(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                )
                              : XPLineChart(dailyXP: _dailyXP),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPLineChart extends StatelessWidget {
  final Map<String, int> dailyXP;

  const XPLineChart({super.key, required this.dailyXP});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final List<FlSpot> spots = [];
    final List<String> dates = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final xp = dailyXP[dateKey]?.toDouble() ?? 0.0;
      spots.add(FlSpot(6 - i.toDouble(), xp));
      dates.add('${date.day}/${date.month}');
    }

    final maxXP = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final maxY = maxXP > 0 ? (maxXP + 20).ceilToDouble() : 50.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Text(
                    '${value.toInt()} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  return Text(
                    dates[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: const Color(0xFFFFA500),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.3),
                  const Color(0xFFFFA500).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final date = dates[spot.x.toInt()];
                return LineTooltipItem(
                  '$date\n${spot.y.toInt()} XP',
                  const TextStyle(
                    color: Color(0xFF6C4AB6),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}
