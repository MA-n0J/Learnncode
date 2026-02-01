import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnncode/providers/state_manager.dart';
import 'package:learnncode/screens/level/level_main.dart';
import 'package:learnncode/screens/login/screen/username.dart';
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController usernameController;
  late final TextEditingController
      parentEmailController; // Added for parent email
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;
  late final FocusNode parentEmailFocusNode; // Added for parent email

  bool isLoginMode = true;
  bool _isLoading = false;
  bool _isDisposing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    usernameController = TextEditingController();
    parentEmailController =
        TextEditingController(); // Initialize parent email controller
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    parentEmailFocusNode = FocusNode(); // Initialize parent email focus node

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _precacheRiveAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocalAuthStatus();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _isDisposing = true;
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    parentEmailController.dispose(); // Dispose parent email controller
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    parentEmailFocusNode.dispose(); // Dispose parent email focus node
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (state == AppLifecycleState.resumed) {
      appState.startTrackingScreenTime();
    } else if (state == AppLifecycleState.paused) {
      appState.stopTrackingScreenTime();
    }
  }

  Future<void> _precacheRiveAssets() async {
    try {
      await rive.RiveFile.asset('assets/RiveAssets/shapes.riv');
      await rive.RiveFile.asset('assets/RiveAssets/login-teddy.riv');
    } catch (e) {
      debugPrint('Error precaching Rive assets: $e');
    }
  }

  Future<void> _checkLocalAuthStatus() async {
    if (!mounted || _isDisposing) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final lastChecked = prefs.getInt('lastAuthCheck') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const threeMonthsInMillis = 3 * 30 * 24 * 60 * 60 * 1000;

      if (isLoggedIn && (now - lastChecked) < threeMonthsInMillis) {
        debugPrint('Using local auth state, within 3-month period');
        await _verifyAuthWithFirebase();
      } else {
        debugPrint('No valid local auth state, staying on login screen');
        await _saveAuthState(false, 0);
      }
    } catch (e) {
      debugPrint('Error checking local auth status: $e');
      if (mounted && !_isDisposing) setState(() => _isLoading = false);
    } finally {
      if (mounted && !_isDisposing) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAuthWithFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _saveAuthState(true, DateTime.now().millisecondsSinceEpoch);
        await _navigateToLearnerScreen();
      } else {
        await _saveAuthState(false, 0);
      }
    } catch (e) {
      debugPrint('Firebase auth verification error: $e');
      await _saveAuthState(false, 0);
    }
  }

  Future<void> _saveAuthState(bool isLoggedIn, int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setInt('lastAuthCheck', timestamp);
  }

  Future<void> _navigateToLearnerScreen() async {
    if (!mounted || _isDisposing) return;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No user authenticated, cannot navigate');
      return;
    }

    final userId = user.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final usernameExists = userDoc.exists && userDoc.data()?['name'] != null;

    await Future.delayed(Duration(milliseconds: 100));

    if (!mounted || _isDisposing) return;

    if (usernameExists) {
      debugPrint('Username exists, navigating to LevelDesignScreen');
      await _navigateToLevelDesign();
    } else {
      debugPrint('No username, navigating to UsernamePromptScreen');
      await _navigateToUsernamePrompt();
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!mounted || _isDisposing) return;
    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveAuthState(true, DateTime.now().millisecondsSinceEpoch);
      await _navigateToLearnerScreen();
    } catch (e) {
      String errorMessage = 'Invalid email or password';
      if (e.toString().contains('user-not-found'))
        errorMessage = 'No user found';
      else if (e.toString().contains('wrong-password'))
        errorMessage = 'Incorrect password';
      debugPrint('Sign-in error: $e');
      _showError(errorMessage);
    } finally {
      if (mounted && !_isDisposing) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (!mounted || _isDisposing) return;
    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();
      final username = usernameController.text.trim().toLowerCase();
      final parentEmail = parentEmailController.text.trim(); // Get parent email

      // Validate learner's email
      if (email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty ||
          username.isEmpty) {
        throw Exception('Please fill in all required fields');
      }
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username) ||
          username.length < 3) {
        throw Exception(
            'Username must be at least 3 characters long and contain only letters, numbers, or underscores');
      }
      // Validate parent email if provided
      if (parentEmail.isNotEmpty) {
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(parentEmail)) {
          throw Exception('Invalid parent email format');
        }
        if (parentEmail.toLowerCase() == email.toLowerCase()) {
          throw Exception('Parent email must be different from learner email');
        }
      }

      // Check if username is taken
      final snapshot = await _firestore
          .collection('usernames')
          .doc(username)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snapshot.exists) {
        throw Exception('This username is already taken');
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final userId = userCredential.user?.uid;

      if (userId == null) {
        throw Exception('User creation failed: No user ID returned');
      }
      await Future.delayed(const Duration(seconds: 1));
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated after creation');
      }

      // Store username and parent email in Firestore
      await _firestore
          .collection('usernames')
          .doc(username)
          .set({'taken': true, 'userId': userId});
      await _firestore.collection('users').doc(userId).set({
        'name': username,
        'email': email,
        'parentEmail': parentEmail.isNotEmpty
            ? parentEmail
            : null, // Store parent email (optional)
      });

      await _saveAuthState(true, DateTime.now().millisecondsSinceEpoch);
      await _navigateToLearnerScreen();
    } catch (e) {
      String errorMessage = 'Sign-up failed: $e';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Failed to connect to the server';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
      }
      debugPrint('Sign-up error: $e');
      _showError(errorMessage);
    } finally {
      if (mounted && !_isDisposing) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted || _isDisposing) return;
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null)
        throw Exception('Authentication failed: No user returned');

      await _saveAuthState(true, DateTime.now().millisecondsSinceEpoch);
      await _navigateToLearnerScreen();
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _showError('Google sign-in failed: $e');
    } finally {
      if (mounted && !_isDisposing) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToLevelDesign() async {
    if (mounted && !_isDisposing) {
      await Future.delayed(Duration(milliseconds: 200));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LevelDesignScreen()),
      );
    }
  }

  Future<void> _navigateToUsernamePrompt() async {
    if (mounted && !_isDisposing) {
      await Future.delayed(Duration(milliseconds: 200));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UsernamePromptScreen()),
      );
    }
  }

  void _showError(String message) {
    if (mounted && !_isDisposing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _isDisposing) return const SizedBox.shrink();

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
              child: SizedBox(
                width: screenWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 10),
                    _buildSubtitle(),
                    const SizedBox(height: 20),
                    _buildModeToggle(),
                    const SizedBox(height: 20),
                    _buildForm(),
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

  Widget _buildLogo() => FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
      );

  Widget _buildTitle() => FadeTransition(
        opacity: _fadeAnimation,
        child: const Text(
          "LearnNcode",
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildSubtitle() => FadeTransition(
        opacity: _fadeAnimation,
        child: const Text(
          "Sign in to continue learning",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildModeToggle() => FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleButton(
                "Login", isLoginMode, () => setState(() => isLoginMode = true)),
            const SizedBox(width: 10),
            _buildToggleButton("Sign Up", !isLoginMode,
                () => setState(() => isLoginMode = false)),
          ],
        ),
      );

  Widget _buildToggleButton(
          String text, bool isActive, VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );

  Widget _buildForm() => SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLoginMode) ...[
                      const SizedBox(height: 16),
                      _buildTextField(usernameController, null, "Username"),
                      const SizedBox(height: 16),
                      _buildTextField(emailController, emailFocusNode, "Email"),
                      const SizedBox(height: 16),
                      _buildTextField(passwordController, passwordFocusNode,
                          "Password", true),
                      const SizedBox(height: 16),
                      _buildTextField(confirmPasswordController, null,
                          "Confirm Password", true),
                      const SizedBox(height: 16),
                      _buildTextField(
                          parentEmailController,
                          parentEmailFocusNode,
                          "Parent's Email (Optional)"), // Added parent email field
                    ] else ...[
                      _buildTextField(emailController, emailFocusNode, "Email"),
                      const SizedBox(height: 16),
                      _buildTextField(passwordController, passwordFocusNode,
                          "Password", true),
                    ],
                    const SizedBox(height: 24),
                    _buildActionButton(
                        !isLoginMode ? "Sign Up" : "Login",
                        !isLoginMode
                            ? _registerWithEmailAndPassword
                            : _signInWithEmailAndPassword),
                    const SizedBox(height: 16),
                    _buildGoogleButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, FocusNode? focusNode,
          String hintText,
          [bool obscureText = false]) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
          ),
          obscureText: obscureText,
          style: const TextStyle(color: Colors.black87),
        ),
      );

  Widget _buildActionButton(String text, VoidCallback onPressed) =>
      AnimatedButton(
        text: text,
        icon: Icons.arrow_forward,
        onPressed: _isLoading
            ? null
            : () {
                emailFocusNode.unfocus();
                passwordFocusNode.unfocus();
                parentEmailFocusNode.unfocus(); // Unfocus parent email
                onPressed();
              },
      );

  Widget _buildGoogleButton() => AnimatedButton(
        text: "Sign in with Google",
        icon: Icons.g_mobiledata,
        onPressed: _isLoading ? null : _signInWithGoogle,
      );
}

class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AnimatedButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.black87, size: 24),
                const SizedBox(width: 10)
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
