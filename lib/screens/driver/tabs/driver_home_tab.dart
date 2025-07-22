// lib/screens/driver/tabs/driver_home_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/screens/driver/log_expense_screen.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/widgets/detail_row.dart';

class DriverHomeTab extends StatefulWidget {
  const DriverHomeTab({super.key});

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  /// Updates the trip status in Firestore and also updates the assigned vehicle's status.
  /// This is an atomic operation using a batch write.
  Future<void> _updateTripStatus(String tripId, String newStatus, String truckId) async {
    setState(() { _isLoading = true; });

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Get a reference to the trip document
      final tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      batch.update(tripRef, {'status': newStatus});

      // 2. Get a reference to the vehicle document and update its status accordingly
      final vehicleRef = FirebaseFirestore.instance.collection('fleet').doc(truckId);
      final String newVehicleStatus = (newStatus == 'InProgress') ? 'On Trip' : 'Available';
      batch.update(vehicleRef, {'status': newVehicleStatus});

      // 3. Commit both writes at the same time
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip status updated to: $newStatus'), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text("User not logged in. Please restart the app."));

    // StreamBuilder listens for the driver's next assigned trip ('Pending' or 'InProgress')
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getDriverActiveTrip(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print(snapshot.error); // For debugging
          return const Center(child: Text('Error loading trip data.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoTripView();
        }

        final activeTripDoc = snapshot.data!.docs.first;
        final tripData = activeTripDoc.data() as Map<String, dynamic>;

        // Conditionally render the UI based on the trip's status
        if (tripData['status'] == 'Pending') {
          return _buildPendingTripView(activeTripDoc);
        } else if (tripData['status'] == 'InProgress') {
          return _buildInProgressTripView(activeTripDoc);
        } else {
          // This should not happen with the current query, but serves as a fallback.
          return _buildNoTripView();
        }
      },
    );
  }

  // --- UI HELPER WIDGETS ---

  /// The screen shown when a trip is assigned but not yet started.
  Widget _buildPendingTripView(DocumentSnapshot tripDoc) {
    final tripData = tripDoc.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Your Next Assignment", style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onBackground)),
          const SizedBox(height: 8),
          Text("Please review the details below and start the trip when you are ready.", style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          _buildRouteCard(tripData),
          const Spacer(), // Pushes the button to the bottom
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _updateTripStatus(tripDoc.id, 'InProgress', tripData['truckId']),
            icon: const Icon(Icons.play_circle_fill_outlined),
            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Start Trip"),
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16)
            ),
          ),
        ],
      ),
    );
  }

  /// The screen shown for a trip that is currently active.
  Widget _buildInProgressTripView(DocumentSnapshot tripDoc) {
    final tripData = tripDoc.data() as Map<String, dynamic>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRouteCard(tripData),
          const SizedBox(height: 16),
          _buildMapPlaceholder(context),
          const SizedBox(height: 16),
          _buildActionButtons(context, tripDoc.id),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _updateTripStatus(tripDoc.id, 'Completed', tripData['truckId']),
            icon: const Icon(Icons.check_circle_outline),
            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Mark as Delivered"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  /// The screen shown when no trips are assigned.
  Widget _buildNoTripView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_transfer, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text("No Active Trip", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("You are currently free. Check back later for new assignments.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: () => setState(() {}), // A simple way to trigger a refresh of the StreamBuilder
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }

  /// A reusable card to display the trip's route and vehicle.
  Widget _buildRouteCard(Map<String, dynamic> tripData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailRow(icon: Icons.unarchive_outlined, label: "Pickup Point", value: tripData['pickupPoint'] ?? 'N/A', iconColor: Colors.lightGreenAccent),
            const Divider(),
            DetailRow(icon: Icons.archive_outlined, label: "Destination Point", value: tripData['deliveryPoint'] ?? 'N/A', iconColor: Colors.redAccent),
            const Divider(),
            DetailRow(icon: Icons.local_shipping_outlined, label: "Assigned Truck", value: tripData['truckId'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  /// A placeholder for a map widget.
  Widget _buildMapPlaceholder(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Container(
        height: 200,
        color: Theme.of(context).cardColor.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 60, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 8),
              const Text("Live Map / Navigation Placeholder", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  /// The row of action buttons for an in-progress trip.
  Widget _buildActionButtons(BuildContext context, String tripId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LogExpenseScreen(tripId: tripId),
              ));
            },
            icon: const Icon(Icons.add_card),
            label: const Text("Log Expense"),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () { /* TODO: Implement call functionality */ },
            icon: const Icon(Icons.call),
            label: const Text("Call Admin"),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }
}