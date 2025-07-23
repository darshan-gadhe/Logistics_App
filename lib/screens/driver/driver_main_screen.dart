// lib/screens/driver/driver_main_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/driver/tabs/driver_documents_tab.dart';
import 'package:logistic_app/screens/driver/tabs/driver_history_tab.dart';
import 'package:logistic_app/screens/driver/tabs/driver_home_tab.dart';
import 'package:logistic_app/screens/common/profile_screen.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/utils/driver_theme.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0;

  // This list now uses late initialization so we can access `userId`
  late final List<Widget> _widgetOptions;
  final String? userId = AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Initialize the list of widgets here
    _widgetOptions = <Widget>[
      const DriverHomeTab(),
      const DriverHistoryTab(),
      const DriverDocumentsTab(),
      if (userId != null)
        ProfileScreen(userId: userId!)
      else
        const Center(child: Text("Error: User not found.")),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE KEY CHANGE ---
    // 1. Detect if the app's current theme is dark.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 2. Choose the correct driver-specific theme (light or dark) to apply.
    final driverThemeData = isDarkMode ? DriverAppTheme.darkTheme : DriverAppTheme.lightTheme;

    // 3. Wrap the Scaffold in a Theme widget to apply our chosen theme.
    return Theme(
      data: driverThemeData,
      child: Scaffold(
        // The body and bottom nav will now use the correct driver theme.
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Documents'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Good for 4 items
        ),
      ),
    );
  }
}