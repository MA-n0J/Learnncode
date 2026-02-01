import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:learnncode/screens/leaderboard/user_profile.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final userId = user.uid;
      final snapshot = await _database.child('users/$userId/followers').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> followersList = [];

        for (var entry in data.entries) {
          final followerId = entry.key as String;

          // Fetch user info from Firestore
          final userDoc =
              await _firestore.collection('users').doc(followerId).get();
          final userData = userDoc.exists ? userDoc.data() : null;

          // Fetch XP from RTDB
          final xpSnapshot =
              await _database.child('users/$followerId/xp').get();
          final xp = xpSnapshot.exists ? xpSnapshot.value as int? ?? 0 : 0;

          if (userData != null) {
            followersList.add({
              'userId': followerId,
              'username': userData['username']?.toString() ?? 'unknown_user',
              'avatarUrl': userData['avatarUrl']?.toString() ?? '',
              'initial': userData['username']?.toString()[0] ?? 'U',
              'color': _getRandomColor(),
              'xp': xp,
            });
          } else {
            followersList.add({
              'userId': followerId,
              'username': 'unknown_user',
              'avatarUrl': '',
              'initial': 'U',
              'color': _getRandomColor(),
              'xp': xp,
            });
          }
        }

        setState(() {
          _followers = followersList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _followers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load followers: $e';
        _isLoading = false;
      });
    }
  }

  String _getRandomColor() {
    List<String> colors = [
      '0xFFB2EBF2',
      '0xFFDCE775',
      '0xFFAED581',
      '0xFFFFD54F',
    ];
    return colors[_followers.length % colors.length];
  }

  void _navigateToUserProfile(
      String userId, String username, String avatarUrl, int xp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          name: username, // Using username as name since no name field exists
          avatarUrl: avatarUrl,
          xp: xp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Followers",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _followers.isEmpty
                  ? const Center(child: Text("No followers found"))
                  : ListView.builder(
                      itemCount: _followers.length,
                      itemBuilder: (context, index) {
                        final follower = _followers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: follower['avatarUrl']!.isNotEmpty
                                  ? NetworkImage(follower['avatarUrl']!)
                                  : null,
                              backgroundColor:
                                  Color(int.parse(follower["color"]!)),
                              child: follower['avatarUrl']!.isEmpty
                                  ? Text(
                                      follower["initial"]!,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    )
                                  : null,
                            ),
                            title: Text(
                              follower['username']!,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _navigateToUserProfile(
                                follower['userId']!,
                                follower['username']!,
                                follower['avatarUrl']!,
                                follower['xp']!,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text("View Profile",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
