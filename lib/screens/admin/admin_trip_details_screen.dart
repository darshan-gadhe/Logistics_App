// lib/screens/admin/admin_trip_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/admin/add_edit_trip_screen.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/widgets/detail_row.dart';

class AdminTripDetailsScreen extends StatelessWidget {
  final DocumentSnapshot trip;
  const AdminTripDetailsScreen({super.key, required this.trip});

  Future<void> _deleteTrip(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().deleteTrip(trip.id);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip deleted successfully.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripData = trip.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Trip',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddEditTripScreen(trip: trip),
              ));
            },
          ),
          // --- THIS IS THE FIX ---
          // Connect the onPressed callback to the _deleteTrip method.
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Trip',
            onPressed: () => _deleteTrip(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Trip Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      DetailRow(icon: Icons.location_on, label: "Pickup Point", value: tripData['pickupPoint'] ?? 'N/A', iconColor: Colors.green),
                      DetailRow(icon: Icons.flag, label: "Delivery Point", value: tripData['deliveryPoint'] ?? 'N/A', iconColor: Colors.red),
                      DetailRow(icon: Icons.person, label: "Assigned Driver", value: tripData['driverName'] ?? 'N/A'),
                      DetailRow(icon: Icons.local_shipping, label: "Assigned Truck", value: tripData['truckId'] ?? 'N/A'),
                      DetailRow(icon: Icons.timelapse, label: "Status", value: tripData['status'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}