// lib/screens/driver/tabs/driver_history_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting, add intl package to pubspec.yaml
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';

class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    final firestoreService = FirestoreService();

    return Column(
      children: [
        // You can add back the stats card here if needed
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Completed Trips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getDriverTripHistory(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error fetching history."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No completed trips found."));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final tripDoc = snapshot.data!.docs[index];
                  final trip = tripDoc.data() as Map<String, dynamic>;

                  // Format the date for display
                  final date = trip['startDate'] is Timestamp
                      ? (trip['startDate'] as Timestamp).toDate()
                      : DateTime.now();
                  final formattedDate = DateFormat('dd-MMM-yyyy').format(date);

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        "${trip['pickupPoint'] ?? ''} -> ${trip['deliveryPoint'] ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text("Trip ID: ${tripDoc.id.substring(0,6)}..."),
                      trailing: Text("${trip['totalKm'] ?? 0} km\n$formattedDate", textAlign: TextAlign.right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}