// lib/screens/admin/add_edit_fleet_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AddEditFleetScreen extends StatefulWidget {
  final DocumentSnapshot? vehicleDoc;
  const AddEditFleetScreen({super.key, this.vehicleDoc});

  @override
  State<AddEditFleetScreen> createState() => _AddEditFleetScreenState();
}

class _AddEditFleetScreenState extends State<AddEditFleetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  late final TextEditingController _idController;
  late final TextEditingController _typeController;
  String _status = 'Available';

  bool get _isEditing => widget.vehicleDoc != null;

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.vehicleDoc!.data() as Map<String, dynamic> : {};
    _idController = TextEditingController(text: _isEditing ? widget.vehicleDoc!.id : '');
    _typeController = TextEditingController(text: data['type'] ?? '');
    _status = data['status'] ?? 'Available';
  }

  @override
  void dispose() {
    _idController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final vehicleData = {
        'type': _typeController.text,
        'status': _status,
      };

      if (_isEditing) {
        await _firestoreService.updateVehicle(widget.vehicleDoc!.id, vehicleData);
      } else {
        if (_idController.text.trim().isEmpty) {
          throw Exception("Vehicle ID / Plate Number cannot be empty.");
        }
        await _firestoreService.addVehicle(_idController.text.trim().toUpperCase(), vehicleData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vehicle ${ _isEditing ? "updated" : "added"} successfully!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Operation failed: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteVehicle() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { _isLoading = true; });
      try {
        await _firestoreService.deleteVehicle(widget.vehicleDoc!.id);
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle deleted.'), backgroundColor: Colors.green));
        // Pop twice to go back to the fleet list screen from the details page
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 1);
      } catch (e) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deletion failed: $e"), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add New Vehicle'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Vehicle',
              onPressed: _isLoading ? null : _deleteVehicle,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _idController,
                readOnly: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Vehicle ID / Plate Number',
                  helperText: _isEditing ? 'ID cannot be changed' : null,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Vehicle Type (e.g., Tata Ace, 22-Wheeler)'),
                validator: (v) => v!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Vehicle Status'),
                items: ['Available', 'On Trip', 'Maintenance']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveVehicle,
                icon: const Icon(Icons.save),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}