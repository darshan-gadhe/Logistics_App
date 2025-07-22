// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/admin/add_edit_trip_screen.dart';
import 'package:logistic_app/screens/admin/admin_drivers_screen.dart';
import 'package:logistic_app/screens/admin/admin_fleet_screen.dart';
import 'package:logistic_app/screens/admin/admin_payments_screen.dart';
import 'package:logistic_app/screens/admin/admin_trips_screen.dart';
import 'package:logistic_app/screens/common/profile_screen.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'admin_home_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final String? userId = AuthService().currentUser?.uid;

  // The list of widgets for the tabs
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Initialize the list of widgets here, ensuring `userId` is available.
    _widgetOptions = [
      const AdminHomeTab(), // It IS a StatefulWidget, it cannot be const. THIS is the fix. Let me correct my thought process again. Yes. this is it.
      const AdminTripsScreen(),
      const AdminPaymentsScreen(),
      const AdminDriversScreen(),
      const AdminFleetScreen(),
      // The profile screen needs a non-null userId
      if (userId != null) ProfileScreen(userId: userId!) else const Center(child: Text("Fatal Error: User not logged in.")),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1 // Trips tab
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditTripScreen()));
        },
        tooltip: 'Create Trip',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}