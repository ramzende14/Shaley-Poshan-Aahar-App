// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTandulEntryCard extends StatefulWidget {
  @override
  _AddTandulEntryCardState createState() => _AddTandulEntryCardState();
}

class _AddTandulEntryCardState extends State<AddTandulEntryCard> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _stockController = TextEditingController();
  final _receivedController = TextEditingController();
  final _totalController = TextEditingController();
  final _dateController = TextEditingController(); // ✅ NEW

  DateTime? _selectedDate;
  String? _selectedMonth;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<Color> repeatedColors = [Colors.blue, Colors.purple]; // ✅ APPBAR COLOR

  @override
  void initState() {
    super.initState();
    _fetchLastStock();
    _receivedController.addListener(_updateTotal);
    _stockController.addListener(_updateTotal);
  }

  void _fetchLastStock() async {
    final snapshot = await _firestore
        .collection('tandul_entries')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final lastData = snapshot.docs.first.data();
      final prevStock = lastData['total']?.toString() ?? '0';
      _stockController.text = prevStock;
    }
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
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = DateFormat('MMMM').format(picked);
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked); // ✅ SET TEXT
      });
    }
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedMonth != null) {
      final data = {
        'date': DateFormat('dd-MM-yyyy').format(_selectedDate!),
        'month': _selectedMonth!,
        'stock': _stockController.text.trim(),
        'received': _receivedController.text.trim(),
        'total': _totalController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('tandul_entries').add(data);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("नोंद यशस्वीरित्या जतन झाली")),
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
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: repeatedColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "नवीन तांदूळ नोंद",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: InputDecoration(
                              labelText: 'तारीख',
                              border: OutlineInputBorder(),
                            ),
                            validator: (_) =>
                                _selectedDate == null ? 'तारीख आवश्यक आहे' : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
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
                        validator: (val) =>
                            val == null || val.isEmpty ? 'महिना आवश्यक आहे' : null,
                      ),
                      SizedBox(height: 10),
                      buildTextField("शिल्लक साठा", _stockController, TextInputType.number),
                      buildTextField("प्राप्त", _receivedController, TextInputType.number),
                      buildTextField("एकूण", _totalController, TextInputType.number, readOnly: true),
                      SizedBox(height: 20),
                     ElevatedButton(
  onPressed: _saveEntry,
  child: Text(
    "जतन करा",
    style: TextStyle(color: Colors.white), // ✅ White text
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  ),
),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      TextInputType keyboardType,
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
        validator: (val) =>
            val == null || val.trim().isEmpty ? "आवश्यक" : null,
      ),
    );
  }
}
