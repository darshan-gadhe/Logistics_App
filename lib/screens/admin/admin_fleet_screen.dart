// lib/screens/admin/admin_fleet_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/admin/add_edit_fleet_screen.dart'; // Make sure this is imported
import 'package:logistic_app/services/firestore_service.dart';

class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    Color getStatusColor(String status) {
      switch (status) {
        case 'On Trip': return Colors.orange;
        case 'Available': return Colors.green;
        case 'Maintenance': return Colors.redAccent;
        default: return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Fleet"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getFleetStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching fleet data."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vehicles found. Tap '+' to add one."));
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final vehicle = document.data()! as Map<String, dynamic>;
              final status = vehicle['status'] ?? 'Unknown';

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.local_shipping,
                    color: getStatusColor(status),
                    size: 40,
                  ),
                  title: Text(document.id, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  subtitle: Text(vehicle['type'] ?? 'No Type'),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: getStatusColor(status).withOpacity(0.15),
                    labelStyle: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddEditFleetScreen(vehicleDoc: document),
                    ));
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      // --- THIS IS THE FIX ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the add/edit screen without passing a document,
          // which signifies that we are creating a *new* vehicle.
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddEditFleetScreen(),
          ));
        },
        tooltip: 'Add Vehicle',
        child: const Icon(Icons.add),
      ),
      // --- END OF FIX ---
    );
  }
}