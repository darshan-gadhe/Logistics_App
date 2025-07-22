// lib/screens/admin/admin_trips_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/admin/admin_trip_details_screen.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AdminTripsScreen extends StatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> with SingleTickerProviderStateMixin {
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
        automaticallyImplyLeading: false,
        title: const Text("Manage Trips"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TripList(status: 'Pending'),
          TripList(status: 'InProgress'),
          TripList(status: 'Completed'),
        ],
      ),
    );
  }
}

// Reusable widget to display a filtered list of trips
class TripList extends StatelessWidget {
  final String status;
  const TripList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getTrips(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading trips."));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        // Filter the documents on the client-side based on the status
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == status;
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Text("No $status trips found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final tripDoc = docs[index];
            final trip = tripDoc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text("${trip['pickupPoint']} -> ${trip['deliveryPoint']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Driver: ${trip['driverName'] ?? 'N/A'}\nTruck: ${trip['truckId'] ?? 'N/A'}"),
                isThreeLine: true,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AdminTripDetailsScreen(trip: tripDoc),
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }
}