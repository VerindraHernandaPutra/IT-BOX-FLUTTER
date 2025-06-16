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
  String? _userImageUrl;
  File? _imageFile; // For immediate preview after editing

  bool _isLoading = true; // Unified loading state
  int _incompleteCount = 0;
  int _completedCount = 0;
  int _certificatesCount = 0;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Unified function to fetch all fresh data from the server
  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user data and activity stats concurrently for speed
      final results = await Future.wait([
        _authService.getUserProfile(),
        _authService.getActivityStats(),
      ]);

      final userData = results[0];
      final statsData = results[1];

      // Update state with fresh data from the server
      if (mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User Name';
          _userEmail = userData['email'] ?? 'user@example.com';
          _userImageUrl = userData['user_image_url'];

          _incompleteCount = statsData['incomplete'] ?? 0;
          _completedCount = statsData['completed'] ?? 0;
          _certificatesCount = statsData['certificates'] ?? 0;

          _isLoading = false;
        });
        // Save the fresh user data back to SharedPreferences
        _saveUserProfileUpdates(
            name: _userName, email: _userEmail, imageUrl: _userImageUrl);
      }
    } catch (e) {
      print("Failed to refresh data: $e");
      if (mounted) {
        // Handle error, e.g., if the user's token expired or they are logged out
        setState(() {
          _isLoading = false;
          _userName = 'Guest';
          _userEmail = 'Please log in';
        });
      }
    }
  }

  // Navigate to edit profile and refresh data upon returning
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _userName,
          initialTitle: _userEmail,
          initialImage: _imageFile,
        ),
      ),
    );

    // After returning from the edit screen, if changes were made...
    if (result != null && mounted) {
      // Update the UI immediately with the data from EditProfileScreen for a snappy feel
      setState(() {
        _userName = result['name'];
        _userEmail = result['title'];
        _imageFile = result['image'];
        _userImageUrl = result['user_image_url'];
      });
      // Save the updated data locally
      _saveUserProfileUpdates(
        name: _userName,
        email: _userEmail,
        imageFile: _imageFile,
        imageUrl: _userImageUrl,
      );
      // Also refresh the stats in case completed courses changed
      _refreshData();
    }
  }

  // Save user data locally to SharedPreferences
  Future<void> _saveUserProfileUpdates(
      {required String name,
        required String email,
        File? imageFile,
        String? imageUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> updatedUserData = {
      'name': name,
      'email': email,
      'user_image_url': imageUrl,
    };
    await prefs.setString('user', jsonEncode(updatedUserData));

    // Persist the local file path for immediate preview on next app open
    if (imageFile != null) {
      await prefs.setString('profile_image_path', imageFile.path);
    } else {
      // If image was removed, clear the path
      await prefs.remove('profile_image_path');
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all local data

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

  // "About Us" dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          title: const Text('About ITCOURSE', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
      // Wrap the body with RefreshIndicator for pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: textPrimary,
        backgroundColor: accentRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(height: 180, width: double.infinity, decoration: const BoxDecoration(color: surfaceDark)),
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
                              border: Border.all(color: primaryDark, width: 4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Show loading indicator for text while fetching data
                        _isLoading
                            ? const CircularProgressIndicator(color: textPrimary, strokeWidth: 2)
                            : Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary), textAlign: TextAlign.center),
                        const SizedBox(height: 5),
                        if (!_isLoading) Text(_userEmail, style: const TextStyle(fontSize: 15, color: textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(alignment: Alignment.centerLeft, child: Text('My Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary))),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: textPrimary))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(_incompleteCount.toString(), 'Incomplete'),
                    _buildStatSeparator(),
                    _buildStatColumn(_completedCount.toString(), 'Completed'),
                    _buildStatSeparator(),
                    _buildStatColumn(_certificatesCount.toString(), 'Certificate'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _navigateToEditProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentRed,
                  foregroundColor: textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              _buildMenuButton(context: context, iconAsset: 'assets/about_us_icon.png', label: 'About Us', onPressed: () => _showAboutDialog(context)),
              const SizedBox(height: 10),
              _buildMenuButton(context: context, iconAsset: 'assets/logout_icon.png', label: 'Logout', onPressed: _logout, isLogout: true),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStatSeparator() {
    return Container(height: 40, width: 1, color: Colors.grey.shade700);
  }

  Column _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuButton({required BuildContext context, required String iconAsset, required String label, required VoidCallback onPressed, bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceDark,
          foregroundColor: isLogout ? Colors.redAccent[100] : textPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Image.asset(iconAsset, width: 22, height: 22, color: isLogout ? Colors.redAccent[100] : textSecondary),
        label: Text(label, style: TextStyle(fontSize: 16, fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}