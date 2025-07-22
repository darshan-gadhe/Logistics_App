enum TripStatus { pending, inProgress, completed, cancelled }

class Trip {
  final String id;
  final String pickupPoint;
  final String deliveryPoint;
  final String driverName;
  final String truckId;
  final TripStatus status;
  final double totalKm;
  final DateTime startDate;

  Trip({
    required this.id,
    required this.pickupPoint,
    required this.deliveryPoint,
    required this.driverName,
    required this.truckId,
    required this.status,
    required this.totalKm,
    required this.startDate,
  });
}