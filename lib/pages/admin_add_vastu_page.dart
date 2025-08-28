// ignore_for_file: use_key_in_widget_constructors, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVastuEntryDialog extends StatefulWidget {
  final String selectedMonth;

  const AddVastuEntryDialog({required this.selectedMonth});

  @override
  State<AddVastuEntryDialog> createState() => _AddVastuEntryDialogState();
}

class _AddVastuEntryDialogState extends State<AddVastuEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _previousStockController = TextEditingController();
  final _receivedThisMonthController = TextEditingController();
  final _totalController = TextEditingController();
  final _usedController = TextEditingController();
  final _remainingController = TextEditingController();
  final _nextMonthDemandController = TextEditingController();

  String getPreviousMonth(String currentMonth) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    int index = months.indexOf(currentMonth);
    return (index <= 0) ? months.last : months[index - 1];
  }

  void _calculateTotalAndRemaining() {
    final prev = double.tryParse(_previousStockController.text) ?? 0;
    final received = double.tryParse(_receivedThisMonthController.text) ?? 0;
    final used = double.tryParse(_usedController.text) ?? 0;

    final total = prev + received;
    final remaining = total - used;

    _totalController.text = total.toStringAsFixed(2);
    _remainingController.text = remaining.toStringAsFixed(2);
  }

  Future<void> _fetchPreviousStock() async {
    final previousMonth = getPreviousMonth(widget.selectedMonth);
    final itemName = _nameController.text.trim();

    if (itemName.isEmpty) return;

    final query = await FirebaseFirestore.instance
        .collection('vastu_records')
        .doc(previousMonth)
        .collection('items')
        .where('name', isEqualTo: itemName)
        .get();

    if (query.docs.isNotEmpty) {
      final prevData = query.docs.first.data();
      final remaining = prevData['remaining'] ?? '0';
      _previousStockController.text = remaining;
    } else {
      _previousStockController.text = '0';
    }

    _calculateTotalAndRemaining();
  }

  @override
  void initState() {
    super.initState();
    _previousStockController.addListener(_calculateTotalAndRemaining);
    _receivedThisMonthController.addListener(_calculateTotalAndRemaining);
    _usedController.addListener(_calculateTotalAndRemaining);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _previousStockController.dispose();
    _receivedThisMonthController.dispose();
    _totalController.dispose();
    _usedController.dispose();
    _remainingController.dispose();
    _nextMonthDemandController.dispose();
    super.dispose();
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'previous_stock': _previousStockController.text.trim(),
        'received_this_month': _receivedThisMonthController.text.trim(),
        'total': _totalController.text.trim(),
        'used': _usedController.text.trim(),
        'remaining': _remainingController.text.trim(),
        'next_month_demand': _nextMonthDemandController.text.trim(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('vastu_records')
            .doc(widget.selectedMonth)
            .collection('items')
            .add(data);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("नवीन वस्तू जतन झाली")),
        );
      } catch (e) {
        print('Error adding data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("डेटा सेव्ह करताना त्रुटी आली")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('नवीन वस्तू'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("वस्तूचे नाव", _nameController, onChanged: (_) => _fetchPreviousStock()),
                _buildField("मागील शिल्लक", _previousStockController, keyboardType: TextInputType.number),
                _buildField("प्राप्त", _receivedThisMonthController, keyboardType: TextInputType.number),
                _buildField("एकूण", _totalController, readOnly: true, keyboardType: TextInputType.number),
                _buildField("वापरले", _usedController, keyboardType: TextInputType.number),
                _buildField("शिल्लक", _remainingController, readOnly: true, keyboardType: TextInputType.number),
                _buildField("पुढील महिन्याची मागणी", _nextMonthDemandController, keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text("रद्द"),
          onPressed: () => Navigator.pop(context),
        ),
       ElevatedButton(
  onPressed: _saveEntry,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
  ),
  child: Text(
    "जतन करा",
    style: TextStyle(color: Colors.white), // ✅ टेक्स्ट पांढरं
  ),
),

      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool readOnly = false, TextInputType keyboardType = TextInputType.text, void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.trim().isEmpty ? "आवश्यक" : null,
      ),
    );
  }
}
