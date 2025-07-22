// lib/screens/admin/add_edit_trip_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AddEditTripScreen extends StatefulWidget {
  final DocumentSnapshot? trip;
  const AddEditTripScreen({super.key, this.trip});

  @override
  State<AddEditTripScreen> createState() => _AddEditTripScreenState();
}

class _AddEditTripScreenState extends State<AddEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _isFetchingData = true;

  late final TextEditingController _amountController;
  late final TextEditingController _pickupController;
  late final TextEditingController _deliveryController;
  List<DocumentSnapshot> _drivers = [];
  List<DocumentSnapshot> _fleet = [];
  String? _selectedDriverId;
  String? _selectedTruckId;
  DateTime _selectedDateTime = DateTime.now();

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.trip!.data() as Map<String, dynamic> : {};
    _pickupController = TextEditingController(text: data['pickupPoint'] ?? '');
    _deliveryController = TextEditingController(text: data['deliveryPoint'] ?? '');
    _selectedDateTime = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');

    _fetchAndSetInitialData();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetInitialData() async {
    // This method is correct.
    try {
      final bool fetchAllTrucks = _isEditing;
      final responses = await Future.wait([
        _firestoreService.getDrivers().first,
        _firestoreService.getFleetStream(fetchOnlyAvailable: !fetchAllTrucks).first,
      ]);
      final driverDocs = responses[0].docs;
      final fleetDocs = responses[1].docs;
      final initialDriverId = _isEditing ? (widget.trip!.data() as Map<String, dynamic>)['driverId'] : null;
      final initialTruckId = _isEditing ? (widget.trip!.data() as Map<String, dynamic>)['truckId'] : null;

      setState(() {
        _drivers = driverDocs;
        _fleet = fleetDocs;
        if (initialDriverId != null && _drivers.any((doc) => doc.id == initialDriverId)) _selectedDriverId = initialDriverId;
        if (initialTruckId != null && _fleet.any((doc) => doc.id == initialTruckId)) _selectedTruckId = initialTruckId;
        _isFetchingData = false;
      });
    } catch (e) {
      print("Failed to fetch dropdown data: $e");
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    // This method is correct.
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDateTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
    if (pickedTime == null) return;
    setState(() => _selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
  }

  // --- THE FIX IS IN THIS METHOD ---
  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final selectedDriverDoc = _drivers.firstWhere((doc) => doc.id == _selectedDriverId);
      final driverName = (selectedDriverDoc.data() as Map<String, dynamic>)['name'];

      final tripData = {
        'pickupPoint': _pickupController.text,
        'deliveryPoint': _deliveryController.text,
        'driverId': _selectedDriverId,
        'driverName': driverName,
        'truckId': _selectedTruckId,
        'status': _isEditing ? (widget.trip!.data() as Map)['status'] : 'Pending',
        'startDate': Timestamp.fromDate(_selectedDateTime),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
      };

      if (_isEditing) {
        await _firestoreService.updateTrip(widget.trip!.id, tripData);
      } else {
        await _firestoreService.addTrip(tripData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip saved successfully!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red));
    } finally {
      // Use mounted check as a best practice before calling setState in async methods.
      if (mounted) {
        setState(() { _isLoading = false; }); // <-- THIS IS THE FIX
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The build method is correct.
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Trip' : 'Create New Trip')),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _pickupController, decoration: const InputDecoration(labelText: 'Pickup Point', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 16),
              TextFormField(controller: _deliveryController, decoration: const InputDecoration(labelText: 'Delivery Point', prefixIcon: Icon(Icons.flag_outlined))),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Trip Amount (INR)', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Please enter a trip amount' : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date & Time'),
                subtitle: Text(DateFormat('EEE, MMM d, yyyy  h:mm a').format(_selectedDateTime)),
                onTap: () => _selectDateTime(context),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedDriverId,
                decoration: const InputDecoration(labelText: 'Assign Driver', prefixIcon: Icon(Icons.person_search)),
                items: _drivers.map<DropdownMenuItem<String>>((doc) => DropdownMenuItem<String>(value: doc.id, child: Text((doc.data() as Map<String, dynamic>)['name']))).toList(),
                onChanged: (val) => setState(() => _selectedDriverId = val),
                validator: (val) => val == null ? 'Please select a driver' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedTruckId,
                decoration: const InputDecoration(labelText: 'Assign Truck', prefixIcon: Icon(Icons.local_shipping_outlined)),
                items: _fleet.map<DropdownMenuItem<String>>((doc) => DropdownMenuItem<String>(value: doc.id, child: Text(doc.id))).toList(),
                onChanged: (val) => setState(() => _selectedTruckId = val),
                validator: (val) => val == null ? 'Please select a truck' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                // This ternary expression now works correctly because setState is always called.
                onPressed: _isLoading ? null : _saveTrip,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}