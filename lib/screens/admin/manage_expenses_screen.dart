// lib/screens/admin/manage_expenses_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ManageExpensesScreen extends StatelessWidget {
  final String tripId;
  final String tripName;

  const ManageExpensesScreen({super.key, required this.tripId, required this.tripName});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(tripName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getExpensesForTrip(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No expenses logged for this trip."));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final expense = doc.data() as Map<String, dynamic>;
              final date = (expense['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(expense['type'] ?? 'Misc', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(expense['description'] ?? 'No description'),
                  leading: CircleAvatar(child: Text('₹${(expense['amount'] ?? 0).toInt()}')),
                  trailing: Text(DateFormat.yMMMd().format(date)),
                  onTap: () => _showExpenseDialog(context, tripId, expenseDoc: doc),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseDialog(context, tripId),
        child: const Icon(Icons.add),
        tooltip: 'Log New Expense',
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, String tripId, {DocumentSnapshot? expenseDoc}) {
    final _formKey = GlobalKey<FormState>();
    final isEditing = expenseDoc != null;
    final FirestoreService firestoreService = FirestoreService();

    String? type = isEditing ? (expenseDoc.data() as Map)['type'] : 'Fuel';
    final amountController = TextEditingController(text: isEditing ? (expenseDoc.data() as Map)['amount'].toString() : '');
    final descController = TextEditingController(text: isEditing ? (expenseDoc.data() as Map)['description'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Expense' : 'Log New Expense'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ['Fuel', 'Maintenance', 'Driver Payment', 'Food', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => type = val,
                    decoration: const InputDecoration(labelText: 'Expense Type'),
                  ),
                  TextFormField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                  TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'type': type,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'description': descController.text,
                    'date': isEditing ? (expenseDoc.data() as Map)['date'] : Timestamp.now()
                  };
                  if (isEditing) {
                    await firestoreService.updateExpenseInTrip(tripId, expenseDoc.id, data);
                  } else {
                    await firestoreService.addExpenseToTrip(tripId, data);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }
}