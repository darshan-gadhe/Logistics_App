// lib/screens/admin/admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/widgets/detail_row.dart'; // We'll reuse this widget

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isDarkMode = true; // Assuming the app is in dark mode by default now

  // Helper method for creating consistent list tiles
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser; // Get the currently logged-in user

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF1E1E1E), // Match card color
                  child: Icon(Icons.shield_outlined, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? "Admin User", // Use display name if available
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? "admin@email.com", // Use user's email
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- BUSINESS DETAILS CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Business Details", style: theme.textTheme.titleLarge),
                    const Divider(height: 24),
                    const DetailRow(icon: Icons.business, label: "Company Name", value: "Logistics Pro Inc."),
                    const DetailRow(icon: Icons.location_city, label: "Address", value: "123 Supply Chain Rd, Mumbai"),
                    const DetailRow(icon: Icons.phone_in_talk, label: "Contact Phone", value: "+91 12345 67890"),
                  ],
                ),
              ),
            ),

            // --- APP SETTINGS CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildSettingsTile(icon: Icons.people_alt_outlined, title: "Manage Staff", subtitle: "Add or remove drivers & admins", onTap: () {}),
                    const Divider(indent: 16, endIndent: 16),
                    _buildSettingsTile(icon: Icons.payment_outlined, title: "Payment Settings", subtitle: "Configure payment methods", onTap: () {}),
                    const Divider(indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: _isDarkMode,
                      onChanged: (bool value) => setState(() => _isDarkMode = value),
                    ),
                  ],
                ),
              ),
            ),

            // --- SECURITY & SUPPORT CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildSettingsTile(icon: Icons.lock_reset_outlined, title: "Change Password", onTap: () {}),
                    const Divider(indent: 16, endIndent: 16),
                    _buildSettingsTile(icon: Icons.help_outline, title: "Help & Support", onTap: () {}),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- LOGOUT BUTTON ---
            ElevatedButton.icon(
              onPressed: () {
                AuthService().signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}