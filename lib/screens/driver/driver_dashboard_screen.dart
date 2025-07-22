import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../utils/constants.dart';

class DriverDashboardScreen extends StatelessWidget {
   DriverDashboardScreen({super.key});

  // Dummy Data: In a real app, this would be fetched from a server.
  final Trip? currentTrip =  null; // Change to a Trip object to see the other state
  // final Trip? currentTrip = Trip(id: "TRIP-001", pickupPoint: "Mumbai Port", deliveryPoint: "Pune Warehouse", driverName: "Ravi Kumar", truckId: "MH01-AB1234", status: TripStatus.InProgress, totalKm: 150, startDate: DateTime.now());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver's Portal"),
        actions: [
          IconButton(icon: const Icon(Icons.support_agent), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentTrip == null
            ? _buildNoTripView(context)
            : _buildActiveTripView(context, currentTrip!),
      ),
    );
  }

  Widget _buildNoTripView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text("No Active Trip", style: kHeadingStyle),
          const Text("You are currently not assigned to any trip.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {}, // TODO: Implement refresh logic
            icon: const Icon(Icons.refresh),
            label: const Text("Check for Trips"),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripView(BuildContext context, Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Current Trip", style: kHeadingStyle),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: kSuccessColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(trip.pickupPoint, style: const TextStyle(fontSize: 16))),
                  ],
                ),
                const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(alignment: Alignment.centerLeft, child: Text("↓", style: TextStyle(fontSize: 20, color: Colors.grey)))),
                Row(
                  children: [
                    const Icon(Icons.flag, color: kErrorColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(trip.deliveryPoint, style: const TextStyle(fontSize: 16))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionChip(context, Icons.map_outlined, "View Map", () => Navigator.pushNamed(context, '/driver_trip_details')),
            _buildActionChip(context, Icons.add_card, "Log Expense", () => Navigator.pushNamed(context, '/log_expense')),
            _buildActionChip(context, Icons.edit_note, "Edit Trip Data", () {}), // e.g. update odometer
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Mark Trip as Completed"),
            style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            child: Icon(icon, size: 30, color: kPrimaryColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}