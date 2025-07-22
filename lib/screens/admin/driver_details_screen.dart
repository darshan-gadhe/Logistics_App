// lib/screens/admin/driver_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/screens/admin/add_edit_driver_screen.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/services/storage_service.dart';
import 'package:logistic_app/widgets/detail_row.dart';
import 'package:photo_view/photo_view.dart';

class DriverDetailsScreen extends StatefulWidget {
  final DocumentSnapshot driverDoc;
  const DriverDetailsScreen({super.key, required this.driverDoc});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> with SingleTickerProviderStateMixin {
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
    final driverData = widget.driverDoc.data() as Map<String, dynamic>;
    final driverId = widget.driverDoc.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(driverData['name'] ?? 'Driver Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddEditDriverScreen(driverDoc: widget.driverDoc),
              ));
            },
            tooltip: 'Edit Driver Profile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Profile Info'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Expenses'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileInfoTab(driverData),
          _buildExpensesTab(driverId),
          _buildDocumentsTab(driverId),
        ],
      ),
    );
  }

  // --- TAB 1: PROFILE INFO ---
  Widget _buildProfileInfoTab(Map<String, dynamic> driverData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DetailRow(icon: Icons.person, label: "Name", value: driverData['name'] ?? 'N/A'),
              DetailRow(icon: Icons.email, label: "Email", value: driverData['email'] ?? 'N/A'),
              DetailRow(icon: Icons.phone, label: "Phone", value: driverData['phone'] ?? 'N/A'),
              DetailRow(
                icon: Icons.local_shipping,
                label: "Assigned Truck",
                value: driverData['assignedTruckId']?.isEmpty ?? true ? 'None' : driverData['assignedTruckId'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 2: EXPENSES ---
  Widget _buildExpensesTab(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getTransactionsForDriver(driverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}. Make sure the Firestore Index is created."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No expenses logged by this driver."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final expense = doc.data() as Map<String, dynamic>;
            final date = (expense['transactionDate'] as Timestamp).toDate();
            final hasReceipt = expense['receiptUrl'] != null && (expense['receiptUrl'] as String).isNotEmpty;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.request_quote_outlined, color: Colors.orange),
                title: Text('₹ ${expense['amount']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${expense['notes'] ?? 'General Expense'}\n${DateFormat.yMMMd().format(date)}"),
                isThreeLine: true,
                trailing: hasReceipt
                    ? IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: () => _viewDocument(context, expense['receiptUrl']),
                  tooltip: 'View Bill Photo',
                )
                    : const Tooltip(
                  message: 'No bill attached',
                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: PERSONAL DOCUMENTS ---
  Widget _buildDocumentsTab(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: StorageService().getDriverDocuments(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No personal documents uploaded."));

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.description, color: Colors.blueAccent),
                title: Text(doc['name'] ?? 'Untitled Document'),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _viewDocument(context, doc['url']),
                  tooltip: 'View Document',
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER METHOD TO VIEW ANY DOCUMENT ---
  void _viewDocument(BuildContext context, String docUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: NetworkImage(docUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ),
      ),
    );
  }
}