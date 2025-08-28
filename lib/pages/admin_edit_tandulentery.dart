// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTandulEntryPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> existingData;

  const EditTandulEntryPage({required this.id, required this.existingData});

  @override
  _EditTandulEntryPageState createState() => _EditTandulEntryPageState();
}

class _EditTandulEntryPageState extends State<EditTandulEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _stockController;
  late TextEditingController _receivedController;
  late TextEditingController _totalController;

  DateTime? _selectedDate;
  String? _selectedMonth;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.existingData['stock'] ?? '');
    _receivedController = TextEditingController(text: widget.existingData['received'] ?? '');
    _totalController = TextEditingController(text: widget.existingData['total'] ?? '');

    _selectedDate = DateFormat('dd-MM-yyyy').parse(widget.existingData['date'] ?? DateTime.now().toString());
    _selectedMonth = widget.existingData['month'];

    _stockController.addListener(_updateTotal);
    _receivedController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final double stock = double.tryParse(_stockController.text) ?? 0.0;
    final double received = double.tryParse(_receivedController.text) ?? 0.0;
    final double total = stock + received;
    _totalController.text = total.toStringAsFixed(2);
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateEntry() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedMonth != null) {
      final updatedData = {
        'date': DateFormat('dd-MM-yyyy').format(_selectedDate!),
        'month': _selectedMonth!,
        'stock': _stockController.text.trim(),
        'received': _receivedController.text.trim(),
        'total': _totalController.text.trim(),
      };

      await _firestore.collection('tandul_entries').doc(widget.id).update(updatedData);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("नोंद अपडेट केली")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("कृपया सर्व आवश्यक माहिती भरा")),
      );
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    _receivedController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('तांदूळ नोंद संपादन'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'तारीख',
                      hintText: _selectedDate == null
                          ? 'तारीख निवडा'
                          : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => _selectedDate == null ? 'तारीख आवश्यक आहे' : null,
                  ),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months
                    .map((month) => DropdownMenuItem(
                          value: month,
                          child: Text(month),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMonth = val),
                decoration: InputDecoration(
                  labelText: 'महिना निवडा',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'महिना आवश्यक आहे' : null,
              ),
              SizedBox(height: 12),
              _buildTextField("शिल्लक साठा", _stockController, TextInputType.number),
              _buildTextField("प्राप्त", _receivedController, TextInputType.number),
              _buildTextField("एकूण", _totalController, TextInputType.number, readOnly: true),
              SizedBox(height: 20),
             ElevatedButton(
  onPressed: _updateEntry,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    padding: const EdgeInsets.symmetric(vertical: 14),
  ),
  child: const Text(
    "जतन करा",
    style: TextStyle(
      color: Colors.white, // ← हे महत्वाचं
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
)

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.trim().isEmpty ? "आवश्यक" : null,
      ),
    );
  }
}

