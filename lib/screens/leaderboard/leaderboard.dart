import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:learnncode/screens/leaderboard/user_profile.dart';
import 'package:learnncode/screens/onboarding/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, this.onItemTapped, this.selectedIndex});

  final Function(int)? onItemTapped;
  final int? selectedIndex;

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<DatabaseEvent>? _usersListener;
  bool _isRefreshing = false;
  String? _lastUpdateHash;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? 1;
    _checkAuthAndFetchData();
  }

  @override
  void dispose() {
    _usersListener?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndFetchData() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated, redirecting to OnboardingScreen');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (Route<dynamic> route) => false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRefreshing = true;
    });

    try {
      await _loadCachedData();
      _fetchLeaderboardData();
    } catch (e) {
      print('Error in _checkAuthAndFetchData: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load leaderboard: $e';
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('leaderboard_data');
    final cachedHash = prefs.getString('leaderboard_hash');

    if (cachedData != null && cachedHash != null) {
      final data = jsonDecode(cachedData) as List<dynamic>;
      setState(() {
        _leaderboardData =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        _lastUpdateHash = cachedHash;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToCache(
      List<Map<String, dynamic>> data, String hash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('leaderboard_data', jsonEncode(data));
    await prefs.setString('leaderboard_hash', hash);
  }

  void _fetchLeaderboardData() {
    _usersListener = _usersRef.onValue.listen((event) async {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> leaderboard = [];

        final currentHash = data.hashCode.toString();

        if (currentHash == _lastUpdateHash && _leaderboardData.isNotEmpty) {
          setState(() {
            _isRefreshing = false;
          });
          return;
        }

        print('RTDB users data: $data');

        for (var entry in data.entries) {
          final userId = entry.key as String;
          final userData = entry.value as Map<dynamic, dynamic>;
          final xp = userData['xp'] as int? ?? 0;

          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          final name = userDoc.exists
              ? userDoc.data()!['name'] as String? ?? 'User'
              : 'User';
          final avatarUrl =
              userDoc.exists ? userDoc.data()!['avatarUrl'] as String? : null;

          print('User $userId - XP: $xp, Name: $name, Avatar: $avatarUrl');

          leaderboard.add({
            'userId': userId,
            'xp': xp,
            'name': name,
            'avatarUrl': avatarUrl,
          });
        }

        leaderboard.sort((a, b) => b['xp'].compareTo(a['xp']));

        for (int i = 0; i < leaderboard.length; i++) {
          leaderboard[i]['rank'] = i + 1;
        }

        if (mounted) {
          setState(() {
            _leaderboardData = leaderboard;
            _isLoading = false;
            _isRefreshing = false;
            _lastUpdateHash = currentHash;
          });
          await _saveToCache(leaderboard, currentHash);
        }
      } else {
        print('No users found in RTDB');
        if (mounted) {
          setState(() {
            _leaderboardData = [];
            _isLoading = false;
            _isRefreshing = false;
          });
          await _saveToCache([], 'empty');
        }
      }
    }, onError: (error) {
      print('Error fetching leaderboard data: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load leaderboard: $error';
          _isRefreshing = false;
        });
      }
    });
  }

  void _navigateToUserProfile(
      String userId, String name, String avatarUrl, int xp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          name: name,
          avatarUrl: avatarUrl ?? '',
          xp: xp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 4,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _checkAuthAndFetchData,
            tooltip: 'Refresh Leaderboard',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green[700],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                )
              : _leaderboardData.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _topThreeWidget(),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _leaderboardData.length,
                            itemBuilder: (context, index) {
                              final user = _leaderboardData[index];
                              return FadeInDown(
                                duration:
                                    Duration(milliseconds: 300 + (index * 100)),
                                child: _leaderboardItem(
                                  user['name'] ?? 'Unknown',
                                  user['xp'] ?? 0,
                                  user['rank'] ?? 0,
                                  user['avatarUrl'] ?? '',
                                  user['userId'] ?? '',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _topThreeWidget() {
    if (_leaderboardData.length < 3) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Not enough users to display top 3.',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final second = _leaderboardData[1];
    final first = _leaderboardData[0];
    final third = _leaderboardData[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[50]!,
            Colors.green[100]!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BounceInDown(
            duration: const Duration(milliseconds: 800),
            child: _topUser(
              second['name'] ?? 'Unknown',
              '2nd',
              second['avatarUrl'] ?? '',
              Colors.grey,
              second['userId'] ?? '',
            ),
          ),
          BounceInDown(
            duration: const Duration(milliseconds: 1000),
            child: _topUser(
              first['name'] ?? 'Unknown',
              '1st',
              first['avatarUrl'] ?? '',
              Colors.amber,
              first['userId'] ?? '',
              isBig: true,
            ),
          ),
          BounceInDown(
            duration: const Duration(milliseconds: 800),
            child: _topUser(
              third['name'] ?? 'Unknown',
              '3rd',
              third['avatarUrl'] ?? '',
              Colors.brown,
              third['userId'] ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _topUser(
      String name, String position, String imageUrl, Color color, String userId,
      {bool isBig = false}) {
    return GestureDetector(
      onTap: () => _navigateToUserProfile(userId, name, imageUrl, 0),
      child: Column(
        children: [
          Text(
            position,
            style: GoogleFonts.inter(
              fontSize: isBig ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isBig ? 45 : 35,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/images/default.png')
                      as ImageProvider,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.star,
            color: color,
            size: isBig ? 50 : 40,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardItem(
      String name, int xp, int rank, String imageUrl, String userId) {
    Color rankColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey
            : rank == 3
                ? Colors.brown
                : Colors.black;

    return GestureDetector(
      onTap: () => _navigateToUserProfile(userId, name, imageUrl, xp),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage('assets/images/default.png')
                        as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [rankColor, rankColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    '$rank',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[900],
            ),
          ),
          subtitle: Text(
            'Rank: $rank',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          trailing: Text(
            'XP: $xp',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
