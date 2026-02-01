import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/LearnNcode.png',
                height: 100), // Replace with your logo
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 10),
            const Text('Loading...', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
