// lib/screens/auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/auth/signup_screen.dart';
import 'package:logistic_app/services/auth_service.dart';

enum UserRole { admin, driver }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    UserCredential? userCredential = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // --- UPDATED AND MORE ROBUST LOGIC ---
    if (userCredential?.user != null) {
      String? firestoreRole = await _authService.getUserRole(userCredential!.user!.uid);
      String selectedRoleOnUI = _selectedRole == UserRole.admin ? 'admin' : 'driver';

      if (!mounted) return;

      if (firestoreRole == null) {
        // CASE 1: User exists in Auth, but not in Firestore (or has no role field).
        await _authService.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile is incomplete. Please sign up again or contact support.')),
        );
      } else if (firestoreRole == selectedRoleOnUI) {
        // CASE 2: SUCCESS! The role in DB matches the role selected on UI.
        if (firestoreRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/driver_main');
        }
        return; // Exit function on success
      } else {
        // CASE 3: Role Mismatch.
        await _authService.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access Denied. You do not have ${_selectedRole.name} permissions.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } else {
      // CASE 4: Login failed (wrong email/password).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Failed. Please check your Login Details .'), backgroundColor: Colors.red),
      );
    }

    setState(() { _isLoading = false; });
  }
  // --- END OF UPDATED LOGIC ---

  @override
  Widget build(BuildContext context) {
    // ... UI is the same as the previous response and is correct ...
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 80,
                  color: theme.primaryColor,
                  shadows: [Shadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4),)],
                ),
                const SizedBox(height: 20),
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
                ),
                Text("Sign in to your account", textAlign: TextAlign.center, style: theme.textTheme.bodyMedium,),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12),),
                  child: ToggleButtons(
                    isSelected: [_selectedRole == UserRole.admin, _selectedRole == UserRole.driver],
                    onPressed: (index) => setState(() => _selectedRole = index == 0 ? UserRole.admin : UserRole.driver),
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: theme.primaryColor,
                    color: theme.colorScheme.primary,
                    renderBorder: false,
                    constraints: BoxConstraints(minHeight: 45.0, minWidth: (MediaQuery.of(context).size.width - 52) / 2),
                    children: const [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.admin_panel_settings_outlined), SizedBox(width: 8), Text('Admin')]),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.drive_eta_outlined), SizedBox(width: 8), Text('Driver')]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Please enter your email' : null,),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}