// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/firebase_options.dart';
import 'package:logistic_app/screens/admin/add_edit_trip_screen.dart'; // <-- IMPORT THE SCREEN
import 'package:logistic_app/screens/auth/login_screen.dart';
import 'package:logistic_app/screens/auth/signup_screen.dart';
import 'package:logistic_app/screens/admin/admin_dashboard_screen.dart';
import 'package:logistic_app/screens/driver/driver_main_screen.dart';
//import 'package:logistic_app/screens/driver/log_expense_screen.dart';
import 'package:logistic_app/services/theme_service.dart';
import 'package:logistic_app/utils/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Logistics Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,


      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        // --- Authentication Routes ---
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),

        // --- Admin Routes ---
        '/admin_dashboard': (context) => const AdminDashboardScreen(),

        // --- THIS IS THE FIX ---
        // Add the route for the AddEditTripScreen.
        '/add_edit_trip': (context) => const AddEditTripScreen(),

        // --- Driver Routes ---
        '/driver_main': (context) => const DriverMainScreen(),
       // '/log_expense': (context) => const LogExpenseScreen(),
      },
    );
  }
}