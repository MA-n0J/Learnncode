import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:learnncode/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnncode/screens/profile/followers.dart';
import 'package:learnncode/screens/profile/following.dart';
import 'package:provider/provider.dart';
import 'package:learnncode/providers/state_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/painting.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onItemTapped, this.selectedIndex});

  final Function(int)? onItemTapped;
  final int? selectedIndex;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;
  bool isRandomAvatar = false;
  Widget _currentAvatar = FluttermojiCircleAvatar(radius: 60);
  File? _uploadedImage;
  String? _avatarUrl;
  String _userName = "User";
  fa.User? _user = fa.FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturingRandomAvatar = false;
  Map<String, int> _dailyXP = {};
  StreamSubscription<DatabaseEvent>? _dailyXPListener;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? 2;
    _loadUserData();
    _loadDailyXP();
  }

  @override
  void dispose() {
    _dailyXPListener?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      final userId = _user!.uid;
      final userSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userSnapshot.exists) {
        setState(() {
          _userName = userSnapshot.data()?['name'] ?? "User";
          _avatarUrl = userSnapshot.data()?['avatarUrl'];
          if (_avatarUrl != null) {
            isRandomAvatar = false;
            _uploadedImage = null;
            final cacheBustedUrl =
                _avatarUrl! + '?t=${DateTime.now().millisecondsSinceEpoch}';
            _currentAvatar = CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(cacheBustedUrl),
              key: UniqueKey(),
            );
          } else {
            isRandomAvatar = false;
            _uploadedImage = null;
            _currentAvatar = FluttermojiCircleAvatar(radius: 60);
          }
        });
      } else {
        await _firestore.collection('users').doc(userId).set({
          'name': _userName,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _loadDailyXP() async {
    if (_user == null) {
      print('No user logged in, skipping dailyXP load');
      setState(() {
        _dailyXP = {};
      });
      return;
    }

    final userId = _user!.uid;
    final dailyXPRef = _database.child('users/$userId/dailyXP');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load daily XP: $error')),
        );
      }
    });
  }

  Future<File> _writeBytesToTempFile(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<void> _updateAvatar(
      {Uint8List? imageBytes,
      XFile? pickedFile,
      bool reset = false,
      bool random = false}) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to update your avatar')),
      );
      return;
    }

    final userId = _user!.uid;
    String? newAvatarUrl;

    try {
      if (_avatarUrl != null) {
        await imageCache.evict(NetworkImage(_avatarUrl!));
        print('Cleared image cache for old avatar URL: $_avatarUrl');
      }

      if (imageBytes != null || pickedFile != null) {
        final fileName = '$userId.jpg';
        String fullPath;
        File fileToUpload;

        if (imageBytes != null) {
          fileToUpload = await _writeBytesToTempFile(imageBytes, fileName);
          print('Uploading file from Uint8List: ${fileToUpload.path}');
        } else {
          fileToUpload = File(pickedFile!.path);
          print('Uploading file from device: ${fileToUpload.path}');
        }

        fullPath = await Supabase.instance.client.storage
            .from('profile-images')
            .upload('public/$fileName', fileToUpload,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ));

        if (fullPath.isEmpty) {
          throw Exception('Failed to upload to Supabase: Empty response');
        }

        newAvatarUrl = Supabase.instance.client.storage
            .from('profile-images')
            .getPublicUrl('public/$fileName');

        newAvatarUrl =
            '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        print('New avatar URL with cache-busting: $newAvatarUrl');

        if (imageBytes != null) {
          await fileToUpload.delete();
        }
      }

      await _firestore.collection('users').doc(userId).set({
        'avatarUrl': newAvatarUrl,
      }, SetOptions(merge: true));

      setState(() {
        _avatarUrl = newAvatarUrl;
        _uploadedImage = pickedFile != null ? File(pickedFile.path) : null;
        isRandomAvatar = random;

        if (reset) {
          _currentAvatar = FluttermojiCircleAvatar(radius: 60);
        } else if (random) {
          _currentAvatar = CircleAvatar(
            radius: 60,
            backgroundColor: Colors.transparent,
            child: RandomAvatar(
              DateTime.now().toIso8601String(),
              height: 120,
              width: 120,
            ),
          );
        } else {
          _currentAvatar = CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(newAvatarUrl!),
            key: UniqueKey(),
          );
        }
      });

      await _loadUserData();
    } catch (e) {
      print('Error in _updateAvatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    }
  }

  Future<Uint8List?> _captureWidgetAsImage(BuildContext context) async {
    final screenshotController = ScreenshotController();
    final imageBytes = await screenshotController.captureFromWidget(
      MediaQuery(
        data: MediaQuery.of(context),
        child: Material(
          child: FluttermojiCircleAvatar(radius: 60),
        ),
      ),
    );
    print(
        'Fluttermoji capture result: ${imageBytes != null ? 'Success (${imageBytes.length} bytes)' : 'Failed'}');
    return imageBytes;
  }

  Future<Uint8List?> _captureRandomAvatar() async {
    final imageBytes = await _screenshotController.capture();
    print(
        'RandomAvatar capture result: ${imageBytes != null ? 'Success (${imageBytes.length} bytes)' : 'Failed'}');
    return imageBytes;
  }

  Future<void> _uploadCustomAvatar() async {
    final imageBytes = await _captureWidgetAsImage(context);
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture avatar image')),
      );
      return;
    }

    await _updateAvatar(imageBytes: imageBytes);
  }

  Future<void> _resetAvatar() async {
    setState(() {
      _isCapturingRandomAvatar = false;
    });
    await _updateAvatar(reset: true);
  }

  Future<void> _generateRandomAvatar() async {
    setState(() {
      _isCapturingRandomAvatar = true;
      _currentAvatar = Screenshot(
        controller: _screenshotController,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.transparent,
          child: RandomAvatar(
            DateTime.now().toIso8601String(),
            height: 120,
            width: 120,
          ),
        ),
      );
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final imageBytes = await _captureRandomAvatar();
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture random avatar image')),
      );
      setState(() {
        _isCapturingRandomAvatar = false;
      });
      return;
    }

    await _updateAvatar(imageBytes: imageBytes, random: true);

    setState(() {
      _isCapturingRandomAvatar = false;
    });
  }

  Future<void> _uploadImage() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) {
        print('Storage permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      print(
          'ImagePicker result: ${pickedFile != null ? 'Success (path: ${pickedFile.path})' : 'Failed'}');
      if (pickedFile != null) {
        await _updateAvatar(pickedFile: pickedFile);
      } else {
        print('No image selected from gallery');
      }
    } catch (e) {
      print('Error in _uploadImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      print('Starting logout process...');

      print('Cancelling dailyXP listener...');
      _dailyXPListener?.cancel();
      _dailyXPListener = null;

      final googleSignIn = GoogleSignIn();
      print('Attempting Google Sign-In sign out...');
      await googleSignIn.signOut();
      print('Google Sign-In sign out successful');

      print('Attempting Firebase sign out...');
      await fa.FirebaseAuth.instance.signOut();
      print('Firebase sign out successful');

      print('Clearing SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences cleared');

      print('Resetting AppState...');
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.resetProgress();
      print('AppState reset successful');

      print('Navigating to OnboardingScreen...');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (Route<dynamic> route) => false,
      );
      print('Navigation to OnboardingScreen complete');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  void _navigateToFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FollowersPage()),
    );
  }

  void _navigateToFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FollowingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SafeArea(
          child: Scaffold(
            extendBodyBehindAppBar: false,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.7),
                        Colors.teal.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
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
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.03,
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (!isRandomAvatar &&
                                    _uploadedImage == null &&
                                    _avatarUrl == null) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(
                                          title: const Text("Customize Avatar"),
                                          leading: IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                        body: FluttermojiCustomizer(),
                                      ),
                                    ),
                                  );
                                  await _uploadCustomAvatar();
                                }
                              },
                              onLongPress: _generateRandomAvatar,
                              onDoubleTap: _uploadImage,
                              child: _currentAvatar,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.blue,
                                ),
                                onPressed: _resetAvatar,
                                tooltip: "Reset Avatar",
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: screenHeight * 0.025,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          "Joined March 2024",
                          style: TextStyle(color: Colors.black54),
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withValues(alpha: 0.8),
                                Colors.teal.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                                child: XPLineChart(dailyXP: _dailyXP),
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
          ),
        );
      },
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
              color: Colors.white.withValues(alpha: 0.2),
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
              colors: [Colors.blue, Colors.blueAccent],
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
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.blueAccent.withValues(alpha: 0.1),
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
                    color: Colors.white,
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
