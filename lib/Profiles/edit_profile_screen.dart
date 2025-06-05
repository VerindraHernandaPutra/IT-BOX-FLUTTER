// lib/Profiles/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/auth_services.dart'; // Import AuthService

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialTitle; // This is the email
  final File? initialImage;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialTitle,
    this.initialImage,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController; // For email
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService(); // Instance of AuthService
  bool _isLoading = false; // To manage loading state for the save button

  // Theme constants
  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedImage = widget.initialImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return; // Prevent picking image while saving
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    if (_nameController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name and Email cannot be empty!'),
            backgroundColor: Colors.orangeAccent),
      );
      return;
    }
    // Basic email format validation (optional, more robust validation is better)
    if (!_titleController.text.contains('@') || !_titleController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid email address.'),
            backgroundColor: Colors.orangeAccent),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to update profile
      final apiResponse = await _authService.updateUserProfile(
        name: _nameController.text.trim(),
        email: _titleController.text.trim(), // Email is in _titleController
      );

      // Extract updated user data from API response if needed, or use local controller text
      // The API response 'user' object should be the source of truth for what was saved.
      final Map<String, dynamic>? updatedUserFromApi = apiResponse['user'] as Map<String, dynamic>?;

      String finalName = _nameController.text.trim();
      String finalEmail = _titleController.text.trim();

      if(updatedUserFromApi != null) {
        finalName = updatedUserFromApi['name'] ?? finalName;
        finalEmail = updatedUserFromApi['email'] ?? finalEmail;
      }

      // Data to return to ProfileScreen
      final resultData = {
        'name': finalName,
        'title': finalEmail, // Email returned as 'title'
        'image': _selectedImage, // Local image selection (not saved to server in this step)
      };

      if (mounted) {
        Navigator.pop(context, resultData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Update failed: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: textPrimary)),
        backgroundColor: surfaceDark,
        iconTheme: const IconThemeData(color: textPrimary),
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: textPrimary, strokeWidth: 2,)),
          )
              : IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Changes',
            onPressed: _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : widget.initialImage != null
                        ? FileImage(widget.initialImage!)
                        : const AssetImage('assets/images/user.jpg') as ImageProvider,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: accentRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryDark, width: 2)
                    ),
                    child: const Icon(Icons.edit_rounded, color: textPrimary, size: 20),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(
              controller: _nameController,
              labelText: 'Full Name',
              icon: Icons.person_outline_rounded,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _titleController,
              labelText: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: _isLoading
                  ? Container() // Hide icon when loading, spinner is part of label
                  : const Icon(Icons.save_alt_rounded, color: textPrimary),
              label: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: textPrimary, strokeWidth: 3,))
                  : const Text('Save Changes', style: TextStyle(color: textPrimary)),
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(color: enabled ? textPrimary : Colors.grey.shade500),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: enabled ? textSecondary : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: enabled ? textSecondary : Colors.grey.shade600),
        filled: true,
        fillColor: surfaceDark.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? accentRed : Colors.grey.shade700),
        ),
        disabledBorder: OutlineInputBorder( // Style for disabled state
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        suffixIcon: readOnly ? const Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20) : null,
      ),
    );
  }
}