import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDailyRecordPage extends StatefulWidget {
  const AddDailyRecordPage({super.key});

  @override
  State<AddDailyRecordPage> createState() => _AddDailyRecordPageState();
}

class _AddDailyRecordPageState extends State<AddDailyRecordPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDay;

  final TextEditingController _presentController = TextEditingController();
  final TextEditingController _lastMonthStockController = TextEditingController();
  final TextEditingController _receivedThisMonthController = TextEditingController();
  final TextEditingController _totalRiceController = TextEditingController();
  final TextEditingController _beneficiaryCountController = TextEditingController();
  final TextEditingController _totalCookedRiceController = TextEditingController();
  final TextEditingController _endMonthRemainingRiceController = TextEditingController();

  bool _headMasterSign = false;

  final List<String> _days = [
    'सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _lastMonthStockController.addListener(_calculateTotalRice);
    _receivedThisMonthController.addListener(_calculateTotalRice);
  }

  @override
  void dispose() {
    _presentController.dispose();
    _lastMonthStockController.dispose();
    _receivedThisMonthController.dispose();
    _totalRiceController.dispose();
    _beneficiaryCountController.dispose();
    _totalCookedRiceController.dispose();
    _endMonthRemainingRiceController.dispose();
    super.dispose();
  }

  void _calculateTotalRice() {
    final last = double.tryParse(_lastMonthStockController.text) ?? 0;
    final received = double.tryParse(_receivedThisMonthController.text) ?? 0;
    _totalRiceController.text = (last + received).toStringAsFixed(2);
    _calculateEndMonthRemaining();
  }

  void _calculateEndMonthRemaining() {
    final total = double.tryParse(_totalRiceController.text) ?? 0;
    final cooked = double.tryParse(_totalCookedRiceController.text) ?? 0;
    _endMonthRemainingRiceController.text = (total - cooked).toStringAsFixed(2);
  }

  Future<double> _fetchCookedRiceForToday() async {
    final firestore = FirebaseFirestore.instance;
    final today = DateTime.now();
    final formattedDate =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final attendanceSnapshot =
        await firestore.collection('studentAttendance').doc(formattedDate).get();

    if (!attendanceSnapshot.exists) return 0;

    final attendanceData = attendanceSnapshot.data()!;
    final studentsSnapshot = await firestore.collection('students').get();
    final Map<String, dynamic> allStudents = {
      for (var doc in studentsSnapshot.docs) doc.id: doc.data()
    };

    int juniorCount = 0;
    int seniorCount = 0;

    for (var entry in attendanceData.entries) {
      if (entry.value['status'] == 'Present') {
        final student = allStudents[entry.key];
        if (student != null) {
          final className = student['class'] ?? '';
          final match = RegExp(r'\d+').firstMatch(className);
          if (match != null) {
            final classNum = int.tryParse(match.group(0)!);
            if (classNum != null) {
              if (classNum >= 1 && classNum <= 5) {
                juniorCount++;
              } else if (classNum >= 6 && classNum <= 8) {
                seniorCount++;
              }
            }
          }
        }
      }
    }

    double juniorKg = juniorCount * 100 / 1000;
    double seniorKg = seniorCount * 150 / 1000;
    return juniorKg + seniorKg;
  }

  Future<void> _fetchInitialData() async {
    try {
      final studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final totalStudents = studentSnapshot.docs.length;
      _presentController.text = totalStudents.toString();
      _beneficiaryCountController.text = totalStudents.toString();

      final previousDailySnapshot = await FirebaseFirestore.instance
          .collection('dailyRecords')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (previousDailySnapshot.docs.isNotEmpty) {
        final prevEntry = previousDailySnapshot.docs.first.data();
        _lastMonthStockController.text = (prevEntry['endMonthRemainingRice'] ?? '0').toString();
      } else {
        final tandulSnapshot = await FirebaseFirestore.instance
            .collection('tandul_entries')
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (tandulSnapshot.docs.isNotEmpty) {
          final latestEntry = tandulSnapshot.docs.first.data();
          _lastMonthStockController.text = (latestEntry['stock'] ?? 0).toString();
          _receivedThisMonthController.text = (latestEntry['received'] ?? 0).toString();
        }
      }

      _calculateTotalRice();

      final cooked = await _fetchCookedRiceForToday();
      _totalCookedRiceController.text = cooked.toStringAsFixed(2);
      _calculateEndMonthRemaining();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("डेटा मिळवताना त्रुटी आली")),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'day': _selectedDay ?? '',
        'present': int.tryParse(_presentController.text) ?? 0,
        'lastMonthStock': _lastMonthStockController.text.trim(),
        'receivedThisMonth': _receivedThisMonthController.text.trim(),
        'totalRice': _totalRiceController.text.trim(),
        'beneficiaryCount': _beneficiaryCountController.text.trim(),
        'totalCookedRice': _totalCookedRiceController.text.trim(),
        'endMonthRemainingRice': _endMonthRemainingRiceController.text.trim(),
        'headMasterSign': _headMasterSign,
        'date': DateTime.now().toIso8601String(),
      };

      try {
        await FirebaseFirestore.instance.collection('dailyRecords').add(data);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("नोंद यशस्वीरीत्या जतन झाली")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("डेटा जतन करताना त्रुटी आली")),
        );
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? "फील्ड आवश्यक आहे" : null,
      ),
    );
  }

  Widget _buildDayDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: _selectedDay,
        decoration: const InputDecoration(
          labelText: 'वार',
          border: OutlineInputBorder(),
        ),
        items: _days
            .map((day) => DropdownMenuItem(value: day, child: Text(day)))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedDay = value;
          });
        },
        validator: (value) => value == null || value.isEmpty ? 'वार आवश्यक आहे' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'नवीन नोंद',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDayDropdown(), // ← Replace dayController with dropdown
              _buildField("पटसंख्या", _presentController, keyboardType: TextInputType.number),
              _buildField("मागील महिना शिल्लक तांदूळ", _lastMonthStockController, keyboardType: TextInputType.number),
              _buildField("चालू महिना प्राप्त तांदूळ", _receivedThisMonthController, keyboardType: TextInputType.number),
              _buildField("एकूण तांदूळ", _totalRiceController, keyboardType: TextInputType.number, readOnly: true),
              _buildField("लाभार्थी संख्या", _beneficiaryCountController, keyboardType: TextInputType.number),
              _buildField("शिजवलेला सर्व तांदूळ", _totalCookedRiceController, keyboardType: TextInputType.number, readOnly: true),
              _buildField("महिना अखेर शिल्लक तांदूळ", _endMonthRemainingRiceController, keyboardType: TextInputType.number, readOnly: true),
              Row(
                children: [
                  Checkbox(
                    value: _headMasterSign,
                    onChanged: (value) {
                      setState(() => _headMasterSign = value!);
                    },
                  ),
                  const Text("मुख्याध्यापक सही"),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveRecord,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    child: const Text(
                      "जतन करा",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
