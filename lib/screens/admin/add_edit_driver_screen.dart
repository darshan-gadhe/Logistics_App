// lib/screens/admin/add_edit_driver_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';

class AddEditDriverScreen extends StatefulWidget {
  final DocumentSnapshot? driverDoc;
  const AddEditDriverScreen({super.key, this.driverDoc});

  @override
  State<AddEditDriverScreen> createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _truckIdController;

  bool get _isEditing => widget.driverDoc != null;

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.driverDoc!.data() as Map<String, dynamic> : {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _truckIdController = TextEditingController(text: data['assignedTruckId'] ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _truckIdController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      if (_isEditing) {
        await _firestoreService.updateUser(widget.driverDoc!.id, {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'assignedTruckId': _truckIdController.text,
        });
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver details updated!")));
      } else {
        await _authService.signUpDriver(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phone: _phoneController.text,
          assignedTruckId: _truckIdController.text,
        );
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New driver created!")));
      }
      if(!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Operation failed: $e")));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  // --- NEW DELETE METHOD ---
  Future<void> _deleteDriver() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to delete this driver? '
                'This will only remove their profile from the app. '
                'Their login account must be deleted from the Firebase console manually.'
        ),
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
        await _firestoreService.deleteDriver(widget.driverDoc!.id);
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver profile deleted.'), backgroundColor: Colors.green));
        Navigator.of(context).pop(); // Pop back to the driver list
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
        title: Text(_isEditing ? 'Edit Driver' : 'Add New Driver'),
        actions: [
          // Show delete button only when editing
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteDriver,
              tooltip: 'Delete Driver',
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address (for login)')),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password (for login)'), obscureText: true),
                const SizedBox(height: 16),
              ],
              TextFormField(controller: _truckIdController, decoration: const InputDecoration(labelText: 'Assigned Truck ID (Optional)')),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDriver,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Update Driver' : 'Create Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}