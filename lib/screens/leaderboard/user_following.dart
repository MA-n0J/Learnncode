import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnncode/screens/leaderboard/user_profile.dart';

class UserFollowingPage extends StatefulWidget {
  final String userId;

  const UserFollowingPage({super.key, required this.userId});

  @override
  _UserFollowingPageState createState() => _UserFollowingPageState();
}

class _UserFollowingPageState extends State<UserFollowingPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot =
          await _database.child('users/${widget.userId}/following').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> followingList = [];

        for (var entry in data.entries) {
          final followingId = entry.key as String;

          // Fetch user info from Firestore
          final userDoc =
              await _firestore.collection('users').doc(followingId).get();
          final userData = userDoc.exists ? userDoc.data() : null;

          // Fetch XP from RTDB
          final xpSnapshot =
              await _database.child('users/$followingId/xp').get();
          final xp = xpSnapshot.exists ? xpSnapshot.value as int? ?? 0 : 0;

          // Only add the user if Firestore data exists and username is present
          if (userData != null && userData['username'] != null) {
            followingList.add({
              'userId': followingId,
              'username': userData['username'].toString(),
              'initial': userData['username'].toString()[0],
              'xp': xp,
            });
          }
        }

        setState(() {
          _users = followingList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load following: $e';
        _isLoading = false;
      });
    }
  }

  Color _getButtonColor(int index) {
    List<Color> colors = [
      Colors.tealAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.lightGreenAccent,
      Colors.teal,
      Colors.green,
      Colors.cyan,
      Colors.lightGreen,
      Colors.tealAccent.shade400,
      Colors.greenAccent.shade400,
    ];
    return colors[index % colors.length];
  }

  void _navigateToUserProfile(String userId, String username, int xp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          name: username,
          avatarUrl: '',
          xp: xp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 5,
        foregroundColor: Colors.white,
        title: const Text(
          "Following",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _users.isEmpty
                  ? const Center(child: Text("Not following anyone"))
                  : ListView.builder(
                      itemCount: _users.length,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: _getButtonColor(index),
                                  child: Text(
                                    user['initial']!.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    user['username']!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToUserProfile(
                                    user['userId']!,
                                    user['username']!,
                                    user['xp']!,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getButtonColor(index),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.visibility, size: 20),
                                  label: const Text("View",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
