import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:learnncode/screens/login/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool isSignInDialogShown = false;
  bool _areAssetsPrecached = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false; // Navigation guard

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _precacheRiveAssets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areAssetsPrecached) {
      _precacheAssets();
      _areAssetsPrecached = true;
    }
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _precacheAssets() async {
    await precacheImage(
        const AssetImage('assets/Backgrounds/Spline.png'), context);
    await precacheImage(const AssetImage("assets/logo/logo.jpg"), context);
  }

  Future<void> _precacheRiveAssets() async {
    await rive.RiveFile.asset('assets/RiveAssets/shapes.riv');
    await rive.RiveFile.asset('assets/RiveAssets/login-teddy.riv');
  }

  void _navigateToHomeScreen() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _onButtonPressed() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
      _navigateToHomeScreen();
      _markOnboardingAsSeen(); // Mark onboarding as seen after navigation
    });
  }

  Future<void> _markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 200,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
              child: const SizedBox(),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            top: isSignInDialogShown ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          Text(
                            "Learn & code",
                            style: TextStyle(
                              fontSize: 60,
                              fontFamily: "Poppins",
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text("Don't skip coding. Learn and code."),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    GestureDetector(
                      onTapDown: (_) => _buttonAnimationController.forward(),
                      onTapUp: (_) {
                        _buttonAnimationController.reverse();
                        _onButtonPressed();
                      },
                      onTapCancel: () => _buttonAnimationController.reverse(),
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          height: 64,
                          width: 260,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_forward),
                              SizedBox(width: 8),
                              Text(
                                "Start now",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Let's get you started",
                        style: TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
