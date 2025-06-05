// lib/Screens/main_screen.dart
import 'package:flutter/material.dart';
import '../Dashboards/dashboard_screen.dart'; // Your existing dashboard
import './course_screen.dart';
import './my_course_screen.dart';
import './profile_screen.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main-screen';
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Default to Dashboard screen

  // List of widgets to call on navigation
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(), // Your Dashboard screen
    CourseScreen(),
    MyCourseScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The AppBar will now be part of each individual screen if needed,
    // or you can have a common AppBar here if the title doesn't change.
    // For this example, individual screens have their own AppBars.
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_rounded),
            label: 'My Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF680d13), // Your theme's accent color
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Color(0xFF1E2125), // Dark background for bottom nav
        type: BottomNavigationBarType.fixed, // Fixed type ensures all labels are visible
        onTap: _onItemTapped,
        showUnselectedLabels: true, // Ensures all labels are visible
      ),
    );
  }
}