// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'login_screen.dart'; // For UserRole enum

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.driver;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    // --- THIS IS THE FIX ---
    // Use a local variable to capture the result of the signup attempt.
    final user;
    String successMessage;

    if (_selectedRole == UserRole.driver) {
      successMessage = 'Driver account created! Please sign in.';
      user = await _authService.signUpDriver(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else { // Admin Signup
      successMessage = 'Admin account created! Please sign in.';
      user = await _authService.signUpAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    // Check the result to give the correct user feedback.
    if (user != null) { // The 'user' variable is now being used here.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green)
      );
      Navigator.of(context).pop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create account. The email may already be in use.'), backgroundColor: Colors.red)
      );
    }
    // --- END OF FIX ---

    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    // The UI Code is correct and does not need changes.
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        titleTextStyle: TextStyle(color: theme.primaryColor, fontSize: 21, fontWeight: FontWeight.w600),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToggleButtons(
                isSelected: [_selectedRole == UserRole.admin, _selectedRole == UserRole.driver],
                onPressed: (index) => setState(() => _selectedRole = index == 0 ? UserRole.admin : UserRole.driver),
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: theme.primaryColor,
                color: theme.colorScheme.primary,
                renderBorder: false,
                constraints: BoxConstraints(minHeight: 45.0, minWidth: (MediaQuery.of(context).size.width - 52) / 2),
                children: const [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.admin_panel_settings_outlined), SizedBox(width: 8), Text('I am an Admin')]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.drive_eta_outlined), SizedBox(width: 8), Text('I am a Driver')]),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Email is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Phone is required' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (v) {
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}