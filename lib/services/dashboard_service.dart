// lib/services/dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // Import rxdart

// --- MODEL: Monthly Overview Metrics ---
class DashboardMetrics {
  final double totalRevenue;
  final double driverPayouts;
  final double fuelExpenses;
  final double netProfit;

  DashboardMetrics({
    required this.totalRevenue,
    required this.driverPayouts,
    required this.fuelExpenses,
    required this.netProfit,
  });
}

// --- MODEL: Live Status Metrics ---
class LiveStatusMetrics {
  final int activeTrips;
  final int trucksOnRoad;
  final int totalTrucks;
  final int maintenanceDueCount;
  final int availableDrivers;
  final double pendingPayoutsAmount;

  LiveStatusMetrics({
    this.activeTrips = 0,
    this.trucksOnRoad = 0,
    this.totalTrucks = 0,
    this.maintenanceDueCount = 0,
    this.availableDrivers = 0,
    this.pendingPayoutsAmount = 0.0,
  });
}

// --- SERVICE CLASS ---
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Monthly Overview ---
  Future<DashboardMetrics> getMonthlyOverview() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));

    final startTimestamp = Timestamp.fromDate(startOfMonth);
    final endTimestamp = Timestamp.fromDate(endOfMonth);

    final querySnapshot = await _firestore
        .collection('transactions')
        .where('transactionDate', isGreaterThanOrEqualTo: startTimestamp)
        .where('transactionDate', isLessThanOrEqualTo: endTimestamp)
        .get();

    double totalRevenue = 0.0;
    double driverPayouts = 0.0;
    double fuelExpenses = 0.0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final notes = (data['notes'] as String?)?.toLowerCase() ?? '';

      if (type == 'received') {
        totalRevenue += amount;
      } else if (type == 'sent') {
        if (notes.contains('driver') || notes.contains('payout') || notes.contains('salary')) {
          driverPayouts += amount;
        } else if (notes.contains('fuel')) {
          fuelExpenses += amount;
        }
      }
    }

    final totalExpenses = driverPayouts + fuelExpenses;
    final netProfit = totalRevenue - totalExpenses;

    return DashboardMetrics(
      totalRevenue: totalRevenue,
      driverPayouts: driverPayouts,
      fuelExpenses: fuelExpenses,
      netProfit: netProfit,
    );
  }

  // --- Live Status Metrics Stream ---
  Stream<LiveStatusMetrics> getLiveStatusMetricsStream() {
    Stream<QuerySnapshot> tripsStream =
    _firestore.collection('trips').where('status', isEqualTo: 'InProgress').snapshots();
    Stream<QuerySnapshot> fleetStream = _firestore.collection('fleet').snapshots();
    Stream<QuerySnapshot> driversStream =
    _firestore.collection('users').where('role', isEqualTo: 'driver').snapshots();
    Stream<QuerySnapshot> pendingPayoutsStream = _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'sent')
        .where('status', isEqualTo: 'Pending')
        .snapshots();

    return Rx.combineLatest4(
      tripsStream,
      fleetStream,
      driversStream,
      pendingPayoutsStream,
          (
          QuerySnapshot trips,
          QuerySnapshot fleet,
          QuerySnapshot drivers,
          QuerySnapshot payouts,
          ) {
        final int activeTripsCount = trips.docs.length;
        final int totalTrucks = fleet.docs.length;
        final int trucksOnRoad = fleet.docs.where((doc) => doc.get('status') == 'On Trip').length;
        final int maintenanceDue = fleet.docs.where((doc) => doc.get('status') == 'Maintenance').length;
        final int availableDrivers = drivers.docs
            .where((doc) =>
        (doc.data() as Map<String, dynamic>).containsKey('availability') &&
            doc.get('availability') == 'Available')
            .length;

        double pendingAmount = 0.0;
        for (var doc in payouts.docs) {
          pendingAmount += (doc.get('amount') as num).toDouble();
        }

        return LiveStatusMetrics(
          activeTrips: activeTripsCount,
          trucksOnRoad: trucksOnRoad,
          totalTrucks: totalTrucks,
          maintenanceDueCount: maintenanceDue,
          availableDrivers: availableDrivers,
          pendingPayoutsAmount: pendingAmount,
        );
      },
    );
  }
}
