import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- USER METHODS ---
  Stream<DocumentSnapshot> getUserStream(String uid) =>
      _firestore.collection('users').doc(uid).snapshots();

  Future<void> updateUser(String uid, Map<String, Object?> data) =>
      _firestore.collection('users').doc(uid).update(data);

  Stream<QuerySnapshot> getDrivers() =>
      _firestore.collection('users').where('role', isEqualTo: 'driver').snapshots();

  Future<void> updateDriver(String uid, Map<String, Object?> data) =>
      _firestore.collection('users').doc(uid).update(data);

  Future<void> deleteDriver(String uid) =>
      _firestore.collection('users').doc(uid).delete();

  Future<DocumentSnapshot?> findUserByName(String name) async {
    final query = await _firestore
        .collection('users')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  // --- TRIP METHODS ---
  Stream<QuerySnapshot> getTrips() =>
      _firestore.collection('trips').orderBy('startDate', descending: true).snapshots();

  Stream<QuerySnapshot> getTripsStream({List<String>? statuses}) {
    Query query = _firestore.collection('trips').orderBy('startDate', descending: true);
    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    return query.snapshots();
  }

  Future<void> addTrip(Map<String, dynamic> tripData) async {
    final double driverEarning = tripData['driverEarning'] ?? 0.0;
    final String driverName = tripData['driverName'];

    final userDoc = await findUserByName(driverName);
    if (userDoc != null) {
      await _firestore.collection('users').doc(userDoc.id).update({
        'totalDue': FieldValue.increment(driverEarning),
      });
    }
    await _firestore.collection('trips').add(tripData);
  }

  Future<void> updateTrip(String id, Map<String, Object?> data) =>
      _firestore.collection('trips').doc(id).update(data);

  Future<void> deleteTrip(String id) =>
      _firestore.collection('trips').doc(id).delete();

  Stream<QuerySnapshot> getDriverActiveTrip(String driverId) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['Pending', 'InProgress'])
        .orderBy('startDate', descending: false)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverTripHistory(String driverId) =>
      _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['Completed', 'Cancelled'])
          .orderBy('startDate', descending: true)
          .snapshots();

  Future<QuerySnapshot> getTripsForPeriod(DateTime start, DateTime end) {
    return _firestore
        .collection('trips')
        .where('startDate', isGreaterThanOrEqualTo: start)
        .where('startDate', isLessThanOrEqualTo: end)
        .get();
  }

  // --- PAYMENT METHODS ---
  Future<DocumentReference> addPayment(Map<String, dynamic> paymentData) async {
    paymentData['createdAt'] = Timestamp.now();
    final String personName = paymentData['name'];
    final double amount = paymentData['amount'];

    final userDoc = await findUserByName(personName);
    if (userDoc != null) {
      await _firestore.collection('users').doc(userDoc.id).update({
        'totalPaid': FieldValue.increment(amount),
      });
    }
    return _firestore.collection('payments').add(paymentData);
  }

  Future<void> updatePayment(String paymentId, Map<String, Object?> data) =>
      _firestore.collection('payments').doc(paymentId).update(data);

  Future<void> deletePayment(String paymentId) async {
    final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
    if (paymentDoc.exists) {
      final data = paymentDoc.data()!;
      final String personName = data['name'];
      final double amount = data['amount'] * -1;

      final userDoc = await findUserByName(personName);
      if (userDoc != null) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'totalPaid': FieldValue.increment(amount),
        });
      }
    }
    return _firestore.collection('payments').doc(paymentId).delete();
  }

  Stream<QuerySnapshot> getPaymentsStream({String? type}) {
    Query query = _firestore.collection('payments').orderBy('createdAt', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots();
  }

  Stream<QuerySnapshot> getPaymentHistoryFor({required String name}) {
    return _firestore
        .collection('payments')
        .where('name', isEqualTo: name)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- TRANSACTION METHODS ---
  Future<DocumentReference> addTransaction(Map<String, dynamic> transactionData) {
    if (transactionData['transactionDate'] == null) {
      transactionData['transactionDate'] = Timestamp.now();
    }
    return _firestore.collection('transactions').add(transactionData);
  }

  Stream<QuerySnapshot> getTransactionsStream({String? type}) {
    Query query = _firestore.collection('transactions').orderBy('transactionDate', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots();
  }

  Future<void> updateTransaction(String transactionId, Map<String, Object?> data) {
    return _firestore.collection('transactions').doc(transactionId).update(data);
  }

  Future<void> deleteTransaction(String transactionId) {
    return _firestore.collection('transactions').doc(transactionId).delete();
  }

  Stream<QuerySnapshot> getTransactionsForDriver(String driverId) {
    return _firestore
        .collection('transactions')
        .where('driverId', isEqualTo: driverId)
        .where('type', isEqualTo: 'sent')
        .orderBy('transactionDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverTransactionsStream(String driverId) {
    return _firestore
        .collection('transactions')
        .where('driverId', isEqualTo: driverId)
        .where('type', isEqualTo: 'sent')
        .orderBy('transactionDate', descending: true)
        .snapshots();
  }

  // --- EXPENSE METHODS ---
  Stream<QuerySnapshot> getExpensesForTrip(String tripId) => _firestore
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots();

  Future<void> addExpenseToTrip(String tripId, Map<String, dynamic> expenseData) =>
      _firestore.collection('trips').doc(tripId).collection('expenses').add(expenseData);

  Future<void> updateExpenseInTrip(String tripId, String expenseId, Map<String, Object?> data) =>
      _firestore.collection('trips').doc(tripId).collection('expenses').doc(expenseId).update(data);

  Future<void> deleteExpenseFromTrip(String tripId, String expenseId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses').doc(expenseId).delete();

  // --- FLEET METHODS ---
  Stream<QuerySnapshot> getFleetStream({bool fetchOnlyAvailable = false}) {
    Query query = _firestore.collection('fleet');
    if (fetchOnlyAvailable) {
      query = query.where('status', isEqualTo: 'Available');
    }
    return query.snapshots();
  }

  Future<void> addVehicle(String vehicleId, Map<String, dynamic> vehicleData) {
    return _firestore.collection('fleet').doc(vehicleId).set(vehicleData);
  }

  Future<void> updateVehicle(String vehicleId, Map<String, Object?> data) {
    return _firestore.collection('fleet').doc(vehicleId).update(data);
  }

  Future<void> deleteVehicle(String vehicleId) {
    return _firestore.collection('fleet').doc(vehicleId).delete();
  }

  // --- TRUCK METHODS ---
  Stream<QuerySnapshot> getTrucks() =>
      _firestore.collection('trucks').snapshots();

  Future<void> addTruck(Map<String, dynamic> truckData) =>
      _firestore.collection('trucks').add(truckData);

  Future<void> updateTruck(String truckId, Map<String, Object?> data) =>
      _firestore.collection('trucks').doc(truckId).update(data);

  Future<void> deleteTruck(String truckId) =>
      _firestore.collection('trucks').doc(truckId).delete();
}
