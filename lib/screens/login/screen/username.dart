import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive/rive.dart' as rive;
import 'package:learnncode/screens/level/level_main.dart';

class UsernamePromptScreen extends StatefulWidget {
  const UsernamePromptScreen({super.key});

  @override
  State<UsernamePromptScreen> createState() => _UsernamePromptScreenState();
}

class _UsernamePromptScreenState extends State<UsernamePromptScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController parentEmailController =
      TextEditingController(); // Added for parent email
  String? errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    parentEmailController.dispose(); // Dispose parent email controller
    super.dispose();
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final snapshot = await _firestore
          .collection('usernames')
          .doc(username)
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.exists;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> _handleSetUsername() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final username = usernameController.text.trim().toLowerCase();
    final parentEmail = parentEmailController.text.trim();
    if (username.isEmpty) {
      setState(() {
        errorMessage = 'Username cannot be empty';
        _isLoading = false;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username) || username.length < 3) {
      setState(() {
        errorMessage =
            'Username must be at least 3 characters long and contain only letters, numbers, or underscores';
        _isLoading = false;
      });
      return;
    }
    // Validate parent email if provided
    if (parentEmail.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(parentEmail)) {
        setState(() {
          errorMessage = 'Invalid parent email format';
          _isLoading = false;
        });
        return;
      }
      final learnerEmail = _auth.currentUser?.email?.toLowerCase() ?? '';
      if (parentEmail.toLowerCase() == learnerEmail) {
        setState(() {
          errorMessage = 'Parent email must be different from learner email';
          _isLoading = false;
        });
        return;
      }
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    if (await _isUsernameTaken(username)) {
      setState(() {
        errorMessage = 'This username is already taken';
        _isLoading = false;
      });
      return;
    }

    try {
      await _firestore.collection('usernames').doc(username).set({
        'taken': true,
        'userId': userId,
      });
      await _firestore.collection('users').doc(userId).set({
        'name': username,
        'email': _auth.currentUser?.email ?? '',
        'parentEmail': parentEmail.isNotEmpty
            ? parentEmail
            : null, // Store parent email (optional)
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LevelDesignScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save username: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: screenWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0E0E0), Color(0xFFB0BEC5)],
              ),
            ),
            child: const rive.RiveAnimation.asset(
              'assets/RiveAssets/shapes.riv',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: screenWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.book_rounded,
                          size: 40,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Set Your Username',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please choose a username to use in the app.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter username',
                                  errorText: errorMessage,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(color: Colors.black87),
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setState(() => errorMessage = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: parentEmailController,
                                decoration: InputDecoration(
                                  hintText: "Parent's Email (Optional)",
                                  errorText: errorMessage,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(color: Colors.black87),
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setState(() => errorMessage = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleSetUsername,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.9),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
