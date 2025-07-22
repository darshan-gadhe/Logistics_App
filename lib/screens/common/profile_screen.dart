// lib/screens/common/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/services/theme_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isEditing = false;
  bool _isLoading = false;

  // A Map to hold the state of our form fields temporarily
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'assignedTruckId': TextEditingController(),
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> userData) {
    _controllers['name']!.text = userData['name'] ?? '';
    _controllers['phone']!.text = userData['phone'] ?? '';
    _controllers['assignedTruckId']!.text = userData['assignedTruckId'] ?? '';
  }

  void _toggleEditMode(Map<String, dynamic>? userData, {bool cancel = false}) {
    setState(() {
      _isEditing = !_isEditing;
      if (cancel && userData != null) _populateControllers(userData);
    });
  }

  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; });
    try {
      final updatedData = {
        'name': _controllers['name']!.text,
        'phone': _controllers['phone']!.text,
        'assignedTruckId': _controllers['assignedTruckId']!.text,
      };

      await _firestoreService.updateUser(widget.userId, updatedData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      setState(() { _isEditing = false; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showThemeDialog(BuildContext context, ThemeService themeService){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setAndSaveTheme(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setAndSaveTheme(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setAndSaveTheme(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the ThemeService from Provider
    final themeService = Provider.of<ThemeService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isEditing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Could not load user profile."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          if (!_isEditing) _populateControllers(userData);

          final bool isDriver = userData['role'] == 'driver';
          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                stretch: true,
                flexibleSpace: _buildFlexibleSpaceBar(userData, theme),
                actions: _isEditing
                    ? [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => _toggleEditMode(userData, cancel: true)),
                  IconButton(icon: const Icon(Icons.check), onPressed: _isLoading ? null : _saveProfile),
                ]
                    : [ IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _toggleEditMode(userData)) ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoSection(isDriver, theme, userData),
                    const SizedBox(height: 16),
                    _buildSettingsSection(theme, themeService),
                    // More sections here...
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlexibleSpaceBar(Map<String, dynamic> userData, ThemeData theme) {
    // This UI helper remains the same, it's already well-designed
    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(color: theme.primaryColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 45,
              backgroundColor: theme.colorScheme.secondary,
              child: Text((userData['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(userData['name'] ?? 'User Name', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(userData['email'] ?? 'user@email.com', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDriver, ThemeData theme, Map<String, dynamic> userData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Personal Information", style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            if(!_isEditing) ...[
              ListTile(leading: const Icon(Icons.email_outlined), title: Text(userData['email'] ?? 'N/A'), subtitle: const Text("Email (Cannot be changed)")),
              ListTile(leading: const Icon(Icons.phone_outlined), title: Text(_controllers['phone']!.text), subtitle: const Text("Phone")),
              if (isDriver) ListTile(leading: const Icon(Icons.local_shipping_outlined), title: Text(_controllers['assignedTruckId']!.text.isEmpty ? "None" : _controllers['assignedTruckId']!.text), subtitle: const Text("Assigned Truck")),
            ] else ...[
              TextFormField(controller: _controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextFormField(controller: _controllers['phone'], decoration: const InputDecoration(labelText: 'Phone Number')),
              if (isDriver) ...[
                const SizedBox(height: 16),
                TextFormField(controller: _controllers['assignedTruckId'], decoration: const InputDecoration(labelText: 'Assigned Truck ID')),
              ]
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, ThemeService themeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings & Preferences", style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text("App Theme"),
              subtitle: Text("${themeService.themeMode.name[0].toUpperCase()}${themeService.themeMode.name.substring(1)} Mode"),
              onTap: () => _showThemeDialog(context, themeService),
            ),
            SwitchListTile(
              title: const Text("Push Notifications"),
              value: true, // You would bind this to a real setting
              onChanged: (val) { /* TODO: Save notification preference */ },
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text("Logout"),
        onPressed: () {
          _authService.signOut();
          if(mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
        style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12)
        ),
      ),
    );
  }
}