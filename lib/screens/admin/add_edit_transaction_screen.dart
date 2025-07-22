import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistic_app/services/firestore_service.dart';
import 'package:logistic_app/services/notification_service.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final DocumentSnapshot? transactionDoc;
  const AddEditTransactionScreen({super.key, this.transactionDoc});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _notificationService = NotificationService();

  bool _isLoading = false;
  bool _isFetchingDrivers = false;
  bool get _isEditing => widget.transactionDoc != null;

  // Form Controllers & State
  late final TextEditingController _partyNameController;
  late final TextEditingController _partyContactController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  List<DocumentSnapshot> _drivers = [];
  String? _selectedDriverId;
  String _type = 'received';
  String _status = 'Completed';
  String _method = 'Online';
  String _expenseCategory = 'Fuel';
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final data = _isEditing ? widget.transactionDoc!.data() as Map<String, dynamic> : {};
    _partyNameController = TextEditingController(text: data['partyName'] ?? '');
    _partyContactController = TextEditingController(text: data['partyContact'] ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _notesController = TextEditingController(text: data['notes'] ?? '');
    _type = data['type'] ?? 'received';
    _status = data['status'] ?? 'Completed';
    _method = data['method'] ?? 'Online';
    _selectedDriverId = data['driverId'];
    _expenseCategory = data['category'] ?? 'Fuel';
    _transactionDate = (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    if (_type == 'sent') {
      _fetchDrivers();
    }
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyContactController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- HELPER METHODS (DEFINED ONLY ONCE) ---

  Future<void> _fetchDrivers() async {
    setState(() => _isFetchingDrivers = true);
    try {
      final snapshot = await _firestoreService.getDrivers().first;
      if (mounted) {
        setState(() => _drivers = snapshot.docs);
      }
    } catch (e) {
      print("Failed to fetch drivers: $e");
    } finally {
      if (mounted) setState(() => _isFetchingDrivers = false);
    }
  }

  void _onDriverSelected(String? driverId) {
    if (driverId == null) return;
    final selectedDriverDoc = _drivers.firstWhere((doc) => doc.id == driverId);
    final driverData = selectedDriverDoc.data() as Map<String, dynamic>;
    setState(() {
      _selectedDriverId = driverId;
      _partyNameController.text = driverData['name'] ?? '';
      _partyContactController.text = driverData['phone'] ?? '';
    });
  }
  // --- END OF HELPER METHODS ---

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final transactionData = {
        'partyName': _partyNameController.text,
        'partyContact': _partyContactController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'notes': _notesController.text,
        'type': _type,
        'status': _status,
        'method': _method,
        'transactionDate': Timestamp.fromDate(_transactionDate),
        'driverId': _type == 'sent' ? _selectedDriverId : null,
        'category': _type == 'sent' ? _expenseCategory : null,
      };

      if (_isEditing) {
        await _firestoreService.updateTransaction(widget.transactionDoc!.id, transactionData);
      } else {
        await _firestoreService.addTransaction(transactionData);
      }

      String message = _type == 'received'
          ? "Dear ${_partyNameController.text}, we have received a payment of INR ${_amountController.text}."
          : "Hi ${_partyNameController.text}, a payout of INR ${_amountController.text} for $_expenseCategory has been sent. Status: $_status.";
      await _notificationService.sendSms(phoneNumber: _partyContactController.text, message: message);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction saved!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _selectDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dt != null) setState(() => _transactionDate = dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'New Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Transaction Type', prefixIcon: Icon(Icons.swap_horiz)),
                items: const [
                  DropdownMenuItem(value: 'received', child: Text('Receive Amount')),
                  DropdownMenuItem(value: 'sent', child: Text('Send Amount (Payout/Expense)')),
                ],
                onChanged: (val) {
                  setState(() => _type = val!);
                  if (_type == 'sent') {
                    _fetchDrivers();
                  } else {
                    _selectedDriverId = null;
                    _partyNameController.clear();
                    _partyContactController.clear();
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_type == 'sent') ...[
                if (_isFetchingDrivers)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else
                  DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Select Driver'),
                    items: _drivers.map((doc) => DropdownMenuItem(value: doc.id, child: Text((doc.data() as Map)['name'])))
                        .toList(),
                    onChanged: _onDriverSelected, // This now correctly references the single method
                    validator: (val) => val == null ? 'Please select a driver for payouts' : null,
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _expenseCategory,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: ['Fuel', 'Food', 'Maintenance', 'Toll/Road Tax', 'Salary', 'Advance', 'Other']
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (val) => setState(() => _expenseCategory = val!),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _partyNameController,
                readOnly: _type == 'sent' && _selectedDriverId != null,
                decoration: InputDecoration(labelText: _type == 'sent' ? 'Driver Name' : 'Customer Name'),
                validator: (val) => val!.isEmpty ? 'Party name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partyContactController,
                readOnly: _type == 'sent' && _selectedDriverId != null,
                decoration: const InputDecoration(labelText: 'Party Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Contact number is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount (INR)'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Amount is required' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: 'Completed', child: Text('Completed')), DropdownMenuItem(value: 'Pending', child: Text('Pending'))], onChanged: (val) => setState(() => _status = val!))),
                  const SizedBox(width: 16),
                  Expanded(child: DropdownButtonFormField<String>(value: _method, decoration: const InputDecoration(labelText: 'Method'), items: const [DropdownMenuItem(value: 'Online', child: Text('Online')), DropdownMenuItem(value: 'Cash', child: Text('Cash')), DropdownMenuItem(value: 'Card', child: Text('Card'))], onChanged: (val) => setState(() => _method = val!))),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Transaction Date'),
                subtitle: Text(DateFormat.yMMMd().format(_transactionDate)),
                onTap: _selectDate,
              ),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveTransaction,
                icon: const Icon(Icons.save),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}