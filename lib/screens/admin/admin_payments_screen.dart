// lib/screens/admin/admin_payments_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/screens/admin/add_edit_transaction_screen.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Ledger"),
        automaticallyImplyLeading: false, // No back button in a tab
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Transactions'),
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      // The TabBarView uses the controller to sync with the TabBar
      body: TabBarView(
        controller: _tabController,
        children: [
          // We use unique Keys to ensure Flutter rebuilds the widget when switching tabs,
          // which is crucial for the stream to get the correct filter parameter.
          const TransactionList(key: PageStorageKey('allTransactions'), type: null),
          const TransactionList(key: PageStorageKey('receivedTransactions'), type: 'received'),
          const TransactionList(key: PageStorageKey('sentTransactions'), type: 'sent'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-payment-fab', // Unique tag to prevent Hero animation errors
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddEditTransactionScreen(),
          ));
        },
        tooltip: 'New Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A reusable widget that fetches and displays a list of transactions.
class TransactionList extends StatelessWidget {
  /// The type of transaction to display: 'received', 'sent', or null for all.
  final String? type;
  const TransactionList({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getTransactionsStream(type: type),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Handle error state
        if (snapshot.hasError) {
          print(snapshot.error); // For debugging
          return const Center(child: Text("Something went wrong."));
        }
        // Handle empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No transactions found in this category."),
          );
        }

        // If data is available, build the list
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildTransactionCard(context, snapshot.data!.docs[index]),
        );
      },
    );
  }

  /// Builds a single, visually informative card for a transaction.
  Widget _buildTransactionCard(BuildContext context, DocumentSnapshot doc) {
    final transaction = doc.data() as Map<String, dynamic>;
    final bool isReceived = transaction['type'] == 'received';
    final bool isPending = transaction['status'] == 'Pending';
    final date = (transaction['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final theme = Theme.of(context);

    // --- Define UI elements based on transaction data ---
    Color avatarColor;
    IconData avatarIcon;
    String subtitleText = transaction['partyName'] ?? 'N/A';

    if (isReceived) {
      avatarColor = Colors.green.shade700;
      avatarIcon = Icons.arrow_downward;
    } else { // Sent
      avatarColor = isPending ? Colors.orange.shade700 : Colors.red.shade700;
      avatarIcon = Icons.arrow_upward;
      // Append the category to the subtitle for 'sent' transactions
      final category = transaction['category'];
      if (category != null && category.isNotEmpty) {
        subtitleText = '$subtitleText • $category';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: isPending ? theme.colorScheme.secondary.withOpacity(0.5) : Colors.transparent,
              width: 1.5
          ),
          borderRadius: BorderRadius.circular(12)
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          foregroundColor: Colors.white,
          child: Icon(avatarIcon),
        ),
        title: Text(
          NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(transaction['amount']),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$subtitleText\n${DateFormat.yMMMd().format(date)}',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(transaction['status'] ?? ''),
          backgroundColor: isPending ? theme.colorScheme.secondary.withOpacity(0.1) : Colors.transparent,
          side: isPending ? BorderSide.none : BorderSide(color: theme.dividerColor),
        ),
        onTap: () {
          // Navigate to the edit screen
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddEditTransactionScreen(transactionDoc: doc),
          ));
        },
      ),
    );
  }
}