// lib/screens/driver/tabs/driver_history_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';

class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    final firestoreService = FirestoreService();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text("Completed Trips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getDriverTripHistory(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // This is the state you are currently in.
                  // Printing the error helps confirm it's an index issue.
                  print(snapshot.error);
                  return const Center(child: Text("Error fetching history. Check console for details."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No completed trips found."));
                }

                // If data is available, build the list
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final tripDoc = snapshot.data!.docs[index];
                    final trip = tripDoc.data() as Map<String, dynamic>;

                    final date = (trip['startDate'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd-MMM-yyyy').format(date);
                    final status = trip['status'] ?? 'Completed';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          status == 'Completed' ? Icons.check_circle : Icons.cancel,
                          color: status == 'Completed' ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          "${trip['pickupPoint'] ?? ''} -> ${trip['deliveryPoint'] ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text("On: $formattedDate"),
                        trailing: Text(
                          status,
                          style: TextStyle(
                              color: status == 'Completed' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}