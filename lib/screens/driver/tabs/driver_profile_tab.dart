// lib/screens/driver/tabs/driver_profile_tab.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/widgets/detail_row.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            // --- HEADER ---
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? "Driver Name", style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text(user?.email ?? "driver@email.com", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),

            // --- VERIFICATION STATUS CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Verification Status", style: theme.textTheme.titleLarge),
                    const Divider(height: 24),
                    const DetailRow(icon: Icons.badge, label: "Driving License", value: "Verified", iconColor: Colors.greenAccent),
                    const DetailRow(icon: Icons.health_and_safety, label: "Medical Certificate", value: "Expires in 3 months", iconColor: Colors.orangeAccent),
                  ],
                ),
              ),
            ),

            // --- ASSIGNED TRUCK CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assigned Truck", style: theme.textTheme.titleLarge),
                    const Divider(height: 24),
                    const DetailRow(icon: Icons.numbers, label: "Truck Number", value: "MH01-AB1234"),
                    const DetailRow(icon: Icons.local_shipping, label: "Model", value: "Tata Ultra 1918.T"),
                    const DetailRow(icon: Icons.build_circle_outlined, label: "Next Maintenance", value: "In 1,450 km"),
                  ],
                ),
              ),
            ),

            // --- APP SETTINGS CARD ---
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Notifications for New Trips"),
                    secondary: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_reset_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    title: const Text("Change Password"),
                    onTap: () {},
                  ),
                ],
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
            ),
          ],
        ),
      ),
    );
  }
}