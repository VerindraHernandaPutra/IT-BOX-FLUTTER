// lib/Screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../Profiles/edit_profile_screen.dart';
import '../Logins/welcome_screen.dart';
import '../Services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Theme and Color Constants
  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  // State Variables
  String _userName = 'Loading...';
  String _userEmail = 'loading@example.com';
  String? _userImageUrl; // To store the image URL from the server
  File? _imageFile;      // For immediate preview after selecting a new image

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user');

    if (!mounted) return;

    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        setState(() {
          _userName = userData['name'] ?? 'User Name';
          _userEmail = userData['email'] ?? 'user@example.com';
          // Load the URL from preferences
          _userImageUrl = userData['user_image_url'];

          // Also load the local file path for fallback/immediate preview
          final String? imagePath = prefs.getString('profile_image_path');
          if (imagePath != null) {
            _imageFile = File(imagePath);
          }
        });
      } catch (e) {
        print("Error decoding user data from SharedPreferences: $e");
        setState(() {
          _userName = 'Error Loading Name';
          _userEmail = 'Error Loading Email';
        });
      }
    } else {
      setState(() {
        _userName = 'Guest';
        _userEmail = 'Please log in';
      });
      print("No user data found in SharedPreferences.");
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _userName,
          initialTitle: _userEmail,
          // Pass the local file if it exists, otherwise the logic in EditProfileScreen will handle it
          initialImage: _imageFile,
        ),
      ),
    );

    // This block executes when we return from EditProfileScreen
    if (result != null && mounted) {
      setState(() {
        _userName = result['name'];
        _userEmail = result['title'];
        _imageFile = result['image']; // The local file for immediate preview
        _userImageUrl = result['user_image_url']; // The new URL from the server

        // Save all updated info, including the new URL, back to preferences
        _saveUserProfileUpdates(
          name: _userName,
          email: _userEmail,
          imageFile: _imageFile,
          imageUrl: _userImageUrl,
        );
      });
    }
  }

  Future<void> _saveUserProfileUpdates({
    required String name,
    required String email,
    File? imageFile,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save the URL within the main 'user' JSON object for consistency
    final Map<String, dynamic> updatedUserData = {
      'name': name,
      'email': email,
      'user_image_url': imageUrl, // Save the new URL here
    };
    await prefs.setString('user', jsonEncode(updatedUserData));

    // Persist the local file path for faster loading/preview across app restarts
    if (imageFile != null) {
      await prefs.setString('profile_image_path', imageFile.path);
    } else {
      // If the image was removed, clear the path
      await prefs.remove('profile_image_path');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all data on logout for a clean slate

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Logout failed: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          title: const Text(
            'About ITCOURSE',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'ITCOURSE is your premier platform for learning cutting-edge IT skills.',
                  style: TextStyle(color: textSecondary, fontSize: 15, height: 1.4),
                ),
                SizedBox(height: 10),
                Text(
                  'Our mission is to provide accessible, high-quality education with industry-relevant curriculum, experienced mentors, and a supportive community to help you achieve your career goals in technology.',
                  style: TextStyle(color: textSecondary, fontSize: 15, height: 1.4),
                ),
                SizedBox(height: 10),
                Text(
                  'Version: 1.0.0\nDeveloped by Kelompok 5.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: accentRed, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0)
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> profileImageProvider;

    // This logic determines which image to show, in order of priority:
    // 1. A new image just selected locally (for instant preview).
    // 2. The image URL from the server.
    // 3. The default placeholder image.
    if (_imageFile != null) {
      profileImageProvider = FileImage(_imageFile!);
    } else if (_userImageUrl != null && _userImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(_userImageUrl!);
    } else {
      profileImageProvider = const AssetImage('assets/user.jpg');
    }

    return Scaffold(
      backgroundColor: primaryDark,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: surfaceDark,
                  ),
                ),
                Positioned(
                  top: 60,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: profileImageProvider,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryDark,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('3', 'In Progress'),
                  _buildStatSeparator(),
                  _buildStatColumn('0', 'Completed'),
                  _buildStatSeparator(),
                  _buildStatColumn('2', 'Certificates'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                foregroundColor: textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildMenuButton(
              context: context,
              iconAsset: 'assets/about_us_icon.png', // Make sure this asset exists
              label: 'About Us',
              onPressed: () {
                _showAboutDialog(context);
              },
            ),
            const SizedBox(height: 10),
            _buildMenuButton(
              context: context,
              iconAsset: 'assets/logout_icon.png', // Make sure this asset exists
              label: 'Logout',
              onPressed: _logout,
              isLogout: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSeparator() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade700,
    );
  }

  Column _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String iconAsset,
    required String label,
    required VoidCallback onPressed,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceDark,
          foregroundColor: isLogout ? Colors.redAccent[100] : textPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Image.asset(iconAsset, width: 22, height: 22, color: isLogout ? Colors.redAccent[100] : textSecondary),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }
}