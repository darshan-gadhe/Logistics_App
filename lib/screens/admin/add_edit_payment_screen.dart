// lib/screens/admin/add_edit_payment_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/services/notification_service.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  Driver({required this.id, required this.name, required this.phone});
}

class AddEditPaymentScreen extends StatefulWidget {
  final DocumentSnapshot? paymentDoc;
  const AddEditPaymentScreen({super.key, this.paymentDoc});

  @override
  State<AddEditPaymentScreen> createState() => _AddEditPaymentScreenState();
}

class _AddEditPaymentScreenState extends State<AddEditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _notificationService = NotificationService();

  bool _isLoading = false;
  bool get _isEditing => widget.paymentDoc != null;

  late final TextEditingController _customerNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String _paymentType = 'customer';
  String _paymentMethod = 'Online';
  String _driverPayoutStatus = 'Pending';

  List<Driver> _driverList = [];
  Driver? _selectedDriver;
  bool _isDriverListLoading = false;

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.paymentDoc!.data() as Map<String, dynamic> : {};

    _customerNameController = TextEditingController(text: data['name'] ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _notesController = TextEditingController(text: data['notes'] ?? '');

    _paymentType = data['type'] ?? 'customer';
    _paymentMethod = data['method'] ?? 'Online';
    _driverPayoutStatus = data['status'] ?? 'Pending';

    if (_paymentType == 'driver') {
      _fetchDrivers(initialDriverName: _isEditing ? data['name'] : null);
    }
  }

  // --- THIS METHOD IS CORRECTED ---
  Future<void> _fetchDrivers({String? initialDriverName}) async {
    setState(() { _isDriverListLoading = true; });
    try {
      final snapshot = await _firestoreService.getDrivers().first;
      final drivers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Driver(id: doc.id, name: data['name'] ?? 'N/A', phone: data['phone'] ?? '');
      }).toList();

      Driver? initialDriver;
      if (initialDriverName != null) {
        try {
          // Find the driver that matches the initial name.
          initialDriver = drivers.firstWhere((d) => d.name == initialDriverName);
        } catch (e) {
          // If no driver is found (e.g., name mismatch or deleted), initialDriver remains null.
          print("Initial driver not found in the list: $e");
          initialDriver = null;
        }
      }

      setState(() {
        _driverList = drivers;
        _selectedDriver = initialDriver; // This is now safe, can be null.
      });

    } catch (e) {
      print("Failed to fetch drivers: $e");
    } finally {
      if(mounted) setState(() { _isDriverListLoading = false; });
    }
  }
  // --- END OF CORRECTION ---

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    // ...The _savePayment logic remains the same and is correct...
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      String nameToSend;
      String phoneToSend;

      if (_paymentType == 'driver') {
        if (_selectedDriver == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a driver.')));
          setState(() { _isLoading = false; });
          return;
        }
        nameToSend = _selectedDriver!.name;
        phoneToSend = _selectedDriver!.phone;
      } else {
        nameToSend = _customerNameController.text;
        phoneToSend = 'DUMMY_PHONE_FOR_CUSTOMER';
      }

      final paymentData = {
        'name': nameToSend,
        'phone': phoneToSend,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'notes': _notesController.text,
        'type': _paymentType,
        'method': _paymentType == 'customer' ? _paymentMethod : null,
        'status': _paymentType == 'driver' ? _driverPayoutStatus : null,
      };

      if (_isEditing) {
        await _firestoreService.updatePayment(widget.paymentDoc!.id, paymentData);
      } else {
        await _firestoreService.addPayment(paymentData);
      }

      await _notificationService.sendSms(
        phoneNumber: phoneToSend,
        message: "A payment of INR ${_amountController.text} regarding your account has been processed. - Logistics Pro",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment saved & notification sent!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... The build method / UI is correct and does not need changes ...
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Payment' : 'Add New Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Payment For'),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer Payment (Incoming)')),
                  DropdownMenuItem(value: 'driver', child: Text('Driver Payout (Outgoing)')),
                ],
                onChanged: _isEditing ? null : (val) {
                  setState(() {
                    _paymentType = val!;
                    if (_paymentType == 'driver' && _driverList.isEmpty) {
                      _fetchDrivers();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_paymentType == 'customer')
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (v) => v!.isEmpty ? 'Customer name is required' : null,
                )
              else
                _isDriverListLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Driver>(
                  value: _selectedDriver,
                  hint: const Text("Select a Driver"),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Driver Name'),
                  items: _driverList.map((driver) {
                    return DropdownMenuItem<Driver>(
                      value: driver,
                      child: Text(driver.name),
                    );
                  }).toList(),
                  onChanged: (Driver? driver) {
                    setState(() {
                      _selectedDriver = driver;
                    });
                  },
                  validator: (v) => v == null ? 'Please select a driver' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (INR)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Amount is required' : null,
              ),
              const SizedBox(height: 16),
              if (_paymentType == 'customer')
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'Online', child: Text('Online (UPI/Bank)')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                  ],
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
              if (_paymentType == 'driver')
                DropdownButtonFormField<String>(
                  value: _driverPayoutStatus,
                  decoration: const InputDecoration(labelText: 'Payout Status'),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  ],
                  onChanged: (val) => setState(() => _driverPayoutStatus = val!),
                ),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)'), maxLines: 2),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePayment,
                icon: _isLoading ? Container() : Icon(_isEditing ? Icons.save : Icons.add),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Update Payment' : 'Save Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}