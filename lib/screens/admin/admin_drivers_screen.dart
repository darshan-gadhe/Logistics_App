// lib/screens/admin/admin_drivers_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/admin/add_edit_driver_screen.dart';
import 'package:logistic_app/screens/admin/driver_details_screen.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AdminDriversScreen extends StatelessWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the service to fetch data
    final FirestoreService firestoreService = FirestoreService();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // Each tab should have its own AppBar for better title management
      appBar: AppBar(
        title: const Text("Manage Drivers"),
        // No back button is needed as this is a primary tab
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the real-time stream of drivers from Firestore
        stream: firestoreService.getDrivers(),
        builder: (context, snapshot) {
          // 1. Handle the loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Handle any errors
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching drivers data."));
          }
          // 3. Handle the case where the collection is empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No drivers found.\nTap the '+' button to add a new driver.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          // 4. If data is available, display it in a ListView
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot document = snapshot.data!.docs[index];
              final driver = document.data()! as Map<String, dynamic>;
              final name = driver['name'] ?? 'No Name';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    foregroundColor: theme.primaryColor,
                    child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Contact: ${driver['phone'] ?? 'N/A'}'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  onTap: () {
                    // Navigate to the details screen to view profile and documents.
                    // Pass the entire document so the details screen has all the data it needs.
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DriverDetailsScreen(driverDoc: document),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
      // Floating Action Button to add a new driver
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the "Add/Edit" screen without passing a document.
          // The screen's logic will know this means we are creating a *new* driver.
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddEditDriverScreen(),
          ));
        },
        tooltip: 'Add New Driver',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}