// lib/screens/driver/driver_trip_details_screen.dart
import 'package:flutter/material.dart';
import 'package:logistic_app/widgets/detail_row.dart';

class DriverTripDetailsScreen extends StatelessWidget {
  const DriverTripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const pickup = "Mumbai Port, Warehouse 7";
    const delivery = "Amazon Fulfillment Center, Pune";
    const distance = "155 km";

    return Scaffold(
      appBar: AppBar(title: const Text('My Trip Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              child: Container(
                height: 250,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation_outlined, size: 60, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 8),
                      const Text("Navigation Map Placeholder", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    DetailRow(icon: Icons.my_location, label: "Pickup From", value: pickup, iconColor: Colors.green),
                    Divider(),
                    DetailRow(icon: Icons.flag_circle, label: "Deliver To", value: delivery, iconColor: Colors.red),
                    Divider(),
                    DetailRow(icon: Icons.social_distance, label: "Estimated Distance", value: distance),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}