// lib/screens/driver/log_expense_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistic_app/services/auth_service.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/services/storage_service.dart';

class LogExpenseScreen extends StatefulWidget {
  final String tripId;
  const LogExpenseScreen({super.key, required this.tripId});

  @override
  State<LogExpenseScreen> createState() => _LogExpenseScreenState();
}

class _LogExpenseScreenState extends State<LogExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _authService = AuthService();
  bool _isLoading = false; // This will now be used

  File? _selectedImageFile;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _expenseType = 'Fuel';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose(); // <-- FIX: Added the required super.dispose() call
  }

  Future<void> _pickImage(ImageSource source) async { // This will now be used
    final image = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (image == null) return;
    setState(() {
      _selectedImageFile = File(image.path);
    });
  }

  Future<void> _logExpense() async { // This will now be used
    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A bill photo is required.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final userDoc = await _firestoreService.getUserStream(user.uid).first;
      final userData = userDoc.data() as Map<String, dynamic>;

      final transactionData = {
        'type': 'sent', 'partyName': userData['name'] ?? 'Driver Expense',
        'partyContact': userData['phone'] ?? '', 'amount': double.tryParse(_amountController.text) ?? 0.0,
        'status': 'Completed', 'method': 'Cash', 'notes': '$_expenseType - ${_notesController.text}',
        'transactionDate': Timestamp.now(), 'driverId': user.uid, 'tripId': widget.tripId, 'receiptUrl': null,
      };

      final docRef = await _firestoreService.addTransaction(transactionData);

      await _storageService.uploadExpenseReceipt(
        uid: user.uid, transactionId: docRef.id, imageFile: _selectedImageFile!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense logged!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log expense: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- THIS IS THE FIX ---
  // The complete `build` method was missing.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Trip Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _pickImage(ImageSource.camera), // Connect the tap gesture
                  child: _selectedImageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImageFile!, fit: BoxFit.cover))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      const Text('Tap to take a photo of the bill', style: TextStyle(color: Colors.grey)),
                      const Text('(Required)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _expenseType,
                decoration: const InputDecoration(labelText: 'Expense Category'),
                items: ['Fuel', 'Food', 'Road Maintenance', 'Toll', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _expenseType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (INR)', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes / Description (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _logExpense, // Connect the button
                icon: const Icon(Icons.save),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
// --- END OF FIX ---
}