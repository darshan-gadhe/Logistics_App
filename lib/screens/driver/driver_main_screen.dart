// lib/screens/driver/driver_main_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/driver/tabs/driver_documents_tab.dart';
import 'package:logistic_app/screens/driver/tabs/driver_history_tab.dart';
import 'package:logistic_app/screens/driver/tabs/driver_home_tab.dart';
import 'package:logistic_app/utils/driver_theme.dart';

import '../../services/auth_service.dart';
import '../common/profile_screen.dart'; // <-- IMPORT THE NEW DRIVER THEME FILE

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0;

  final String userId = AuthService().currentUser!.uid;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const DriverHomeTab(),
      const DriverHistoryTab(),
      const DriverDocumentsTab(),
      ProfileScreen(userId: userId), // <-- REPLACE with new ProfileScreen
    ];
  }


  static const List<String> _appBarTitles = <String>[
    "Current Trip",
    "Trip History",
    "My Documents",
    "My Profile",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // THIS IS THE KEY CHANGE: We wrap the Scaffold in a Theme widget
    // to apply our custom driver theme.
    return Theme(
      data: DriverAppTheme.getThemeOverride(context), // <-- APPLY THE NEW THEME HERE
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[_selectedIndex]),
          backgroundColor: DriverAppTheme.driverCardColor,
          elevation: 1,
        ),
        body: Center(
          child:IndexedStack(index: _selectedIndex, children: _widgetOptions,),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Documents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}