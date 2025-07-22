// lib/screens/admin/add_edit_truck_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AddEditTruckScreen extends StatefulWidget {
  final DocumentSnapshot? truckDoc;
  const AddEditTruckScreen({super.key, this.truckDoc});

  @override
  State<AddEditTruckScreen> createState() => _AddEditTruckScreenState();
}

class _AddEditTruckScreenState extends State<AddEditTruckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  late final TextEditingController _idNumberController;
  late final TextEditingController _typeController;
  String? _selectedStatus;

  bool get _isEditing => widget.truckDoc != null;

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.truckDoc!.data() as Map<String, dynamic> : {};
    _idNumberController = TextEditingController(text: data['idNumber'] ?? '');
    _typeController = TextEditingController(text: data['type'] ?? '');
    _selectedStatus = data['status'] ?? 'Available';
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _saveTruck() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final truckData = {
      'idNumber': _idNumberController.text,
      'type': _typeController.text,
      'status': _selectedStatus
    };

    try {
      if (_isEditing) {
        await _firestoreService.updateTruck(widget.truckDoc!.id, truckData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Truck details updated!")));
      } else {
        await _firestoreService.addTruck(truckData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New truck added to fleet!")));
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Operation failed: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Truck' : 'Add New Truck')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _idNumberController, decoration: const InputDecoration(labelText: 'Truck ID / Number Plate'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Truck Type (e.g., 22-Wheeler Truck)'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Available', 'On Trip', 'Maintenance'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTruck,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Update Truck' : 'Add Truck'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}