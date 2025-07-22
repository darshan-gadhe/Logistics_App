// lib/screens/admin/tabs/admin_home_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/services/dashboard_service.dart';
import 'package:logistic_app/widgets/dashboard_stat_card.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});
  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  late Future<DashboardMetrics> _monthlyMetricsFuture;
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _monthlyMetricsFuture = _dashboardService.getMonthlyOverview();
  }

  void _refreshMonthlyOverview() {
    setState(() {
      _monthlyMetricsFuture = _dashboardService.getMonthlyOverview();
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMonthlyOverview,
            tooltip: "Refresh Monthly Stats",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This Month's Overview", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<DashboardMetrics>(
              future: _monthlyMetricsFuture,
              builder: (context, snapshot) {
                // ... (This FutureBuilder is correct and does not need changes)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading overview:\n${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                  );
                }
                if (snapshot.hasData) {
                  final metrics = snapshot.data!;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardStatCard(title: 'Total Revenue', value: _formatCurrency(metrics.totalRevenue), icon: Icons.attach_money, iconColor: Colors.green),
                      DashboardStatCard(title: 'Net Profit', value: _formatCurrency(metrics.netProfit), icon: Icons.trending_up, iconColor: Colors.lightBlueAccent),
                      DashboardStatCard(title: 'Fuel Expenses', value: _formatCurrency(metrics.fuelExpenses), icon: Icons.local_gas_station, iconColor: Colors.redAccent),
                      DashboardStatCard(title: 'Driver Payouts', value: _formatCurrency(metrics.driverPayouts), icon: Icons.payments_outlined, iconColor: Colors.orange),
                    ],
                  );
                }
                return const Center(child: Text("No overview data available."));
              },
            ),
            const SizedBox(height: 24),

            Text("Live Company Status", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            StreamBuilder<LiveStatusMetrics>(
              stream: _dashboardService.getLiveStatusMetricsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("No live data available."));
                }

                final liveMetrics = snapshot.data!;
                return GridView.count(
                  crossAxisCount: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildLiveMetricTile(theme, Icons.route_outlined, Colors.blue, "Active Trips", "${liveMetrics.activeTrips}"),
                    _buildLiveMetricTile(theme, Icons.local_shipping_outlined, Colors.orange, "Trucks on Road", "${liveMetrics.trucksOnRoad} / ${liveMetrics.totalTrucks}"),
                    _buildLiveMetricTile(theme, Icons.person_outline, Colors.green, "Available Drivers", "${liveMetrics.availableDrivers}"),
                    _buildLiveMetricTile(theme, Icons.build_circle_outlined, Colors.redAccent, "Maintenance Due", "${liveMetrics.maintenanceDueCount}"),
                    _buildLiveMetricTile(theme, Icons.payments_outlined, Colors.purpleAccent, "Pending Payouts", _formatCurrency(liveMetrics.pendingPayoutsAmount)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- THIS IS THE DEFINITIVE FIX ---
  // The Column is now wrapped in a FittedBox to prevent any possible overflow.
  Widget _buildLiveMetricTile(ThemeData theme, IconData icon, Color iconColor, String title, String value) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox( // Wrap the entire Column in a FittedBox
                fit: BoxFit.scaleDown, // Use scaleDown to only shrink if needed
                alignment: Alignment.centerLeft, // Align content to the left
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium,
                    ),
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