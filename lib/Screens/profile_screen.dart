// lib/Screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

// TODO: Verify these import paths and THE CLASS NAMES DEFINED IN THOSE FILES
import '../Profiles/edit_profile_screen.dart'; // Assuming the class is EditProfileScreen
import '../Logins/login_screen.dart';       // Assuming the class is LoginScreen
import '../Services/auth_services.dart';   // Assuming your AuthService is here
import '../Logins/welcome_screen.dart';    // For logout navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  String _userName = 'Loading...';
  String _userEmail = 'loading@example.com';
  File? _imageFile;

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
          initialImage: _imageFile,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _userName = result['name'];
        _userEmail = result['title'];
        _imageFile = result['image'];
        _saveUserProfileUpdates(name: _userName, email: _userEmail, imageFile: _imageFile);
      });
    }
  }

  Future<void> _saveUserProfileUpdates({required String name, required String email, File? imageFile}) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> updatedUserData = {
      'name': name,
      'email': email,
    };
    await prefs.setString('user', jsonEncode(updatedUserData));
    if (imageFile != null) {
      await prefs.setString('profile_image_path', imageFile.path);
    } else {
      await prefs.remove('profile_image_path');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('profile_image_path');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()), // Navigate to WelcomeScreen
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

  // New method to show the About Us dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceDark, // Dark background for the dialog
          title: const Text(
            'About ITCOURSE',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView( // Makes content scrollable if it's too long
            child: ListBody( // Use ListBody for multiple text paragraphs
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
                  'Version: 1.0.0\nDeveloped by Kelompok 5.', // Example version info
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: accentRed, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
          shape: RoundedRectangleBorder( // Optional: give the dialog rounded corners
              borderRadius: BorderRadius.circular(12.0)
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> profileImageProvider;
    if (_imageFile != null) {
      profileImageProvider = FileImage(_imageFile!);
    } else {
      profileImageProvider = const AssetImage('assets/user.jpg');
    }

    return Scaffold(
      backgroundColor: primaryDark,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack( /* ... Your existing Stack for profile header ... */
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
            const Padding( /* ... Your "My Activity" section ... */
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
            Padding( /* ... Your stats Row ... */
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
            ElevatedButton( /* ... Your Edit Profile Button ... */
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
              iconAsset: 'assets/about_us_icon.png',
              label: 'About Us',
              onPressed: () {
                _showAboutDialog(context); // <<< CALLING THE NEW DIALOG METHOD
              },
            ),
            const SizedBox(height: 10),
            _buildMenuButton(
              context: context,
              iconAsset: 'assets/logout_icon.png',
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

  Widget _buildStatSeparator() { /* ... Your _buildStatSeparator method ... */
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade700,
    );
  }

  Column _buildStatColumn(String value, String label) { /* ... Your _buildStatColumn method ... */
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

  Widget _buildMenuButton({ /* ... Your _buildMenuButton method ... */
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