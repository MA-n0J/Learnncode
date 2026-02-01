import 'package:flutter/material.dart';
import 'package:learnncode/screens/onboarding/onboarding_screen.dart';
import 'package:learnncode/screens/login/home_screen.dart';
import 'package:learnncode/screens/level/level_main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:learnncode/providers/state_manager.dart';
import 'package:learnncode/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ Include the OneSignal package
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rtbkqyakjpfdhuweebnt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0YmtxeWFranBmZGh1d2VlYm50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MjE4NjEsImV4cCI6MjA1OTE5Nzg2MX0.IB_xlgLOiZOUyY_gkLVLtxHlU7SnTUqnJ4CTMsClx9s',
  );

  // ✅ Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // for debugging
  OneSignal.initialize(
      "95ecc7de-3418-4564-b508-d913ac44700d"); // replace with your OneSignal App ID
  OneSignal.Notifications.requestPermission(true);

  // ✅ Initialize local notification service (if needed)
  await NotificationService.initialize();

  // ✅ Handle deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      print('Received deep link: $uri');
    }
  });

  // ✅ Onboarding & login state
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;

  // ✅ Notification permission check
  final notificationStatus = await Permission.notification.status;
  Widget initialScreen;

  if ((notificationStatus.isDenied || notificationStatus.isPermanentlyDenied)) {
    initialScreen = const PermissionPromptScreen();
  } else if (hasSeenOnboarding && isLoggedIn) {
    initialScreen = const LevelDesignScreen();
  } else if (hasSeenOnboarding) {
    initialScreen = const HomeScreen();
  } else {
    initialScreen = const OnboardingScreen();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Flutter Way',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        fontFamily: "Intel",
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),
      home: initialScreen,
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);

class PermissionPromptScreen extends StatelessWidget {
  const PermissionPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enable Notifications',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'We need notification permissions to send you daily learning reminders and keep your streak alive!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Permission.notification.request();
                  if (await Permission.notification.status.isGranted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LevelDesignScreen(),
                      ),
                    );
                  } else {
                    await openAppSettings();
                  }
                },
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
