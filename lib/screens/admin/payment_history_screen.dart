// lib/screens/admin/payment_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/widgets/balance_card.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final String personName;
  const PaymentHistoryScreen({super.key, required this.personName});

  // --- THIS IS THE FIX ---
  // A helper function to safely convert the nullable Future to a non-nullable Stream.
  Stream<DocumentSnapshot> _getUserStream(FirestoreService service, String name) async* {
    final userDoc = await service.findUserByName(name);
    if (userDoc != null && userDoc.exists) {
      // If we find the document, yield it into the stream.
      yield userDoc;
    }
    // If not found, the stream will simply be empty, which the StreamBuilder handles gracefully.
  }
  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text("History for $personName")),
      body: Column(
        children: [
          // USER BALANCE STREAM
          StreamBuilder<DocumentSnapshot>(
            stream: _getUserStream(firestoreService, personName), // <-- Use the new helper method
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("Loading user balance...")),
                );
              }
              if (!userSnapshot.hasData) {
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Could not find a user profile for '$personName'. Balance tracking is unavailable.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              return BalanceCard(
                title: "Overall Balance",
                totalDue: (userData['totalDue'] ?? 0.0).toDouble(),
                totalPaid: (userData['totalPaid'] ?? 0.0).toDouble(),
              );
            },
          ),

          // EXISTING PAYMENT LIST
          const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text("Transaction History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getPaymentHistoryFor(name: personName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text("Error loading payment history."));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No payment history found."));

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final payment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final bool isCustomerPayment = payment['type'] == 'customer';
                    final date = (payment['createdAt'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isCustomerPayment ? "Amount Received" : "Amount Paid",
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                            ),
                            if ((payment['notes'] ?? '').isNotEmpty) ...[
                              const Divider(height: 20),
                              Text("Notes: ${payment['notes']}"),
                            ]
                          ],
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