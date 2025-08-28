import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoshanTablePage extends StatefulWidget {
  const PoshanTablePage({super.key});

  @override
  State<PoshanTablePage> createState() => _PoshanTablePageState();
}

class _PoshanTablePageState extends State<PoshanTablePage> {
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String selectedMonth = '';
  final List<String> columnHeaders = [
    "दैनिक उपस्थिती", "ताटांची संख्या", "मूगडाळ", "तूरडाळ", "मसूरडाळ",
    "मटकी", "मूग", "चवळी", "हरभरा", "वाटाणा", "जिरे", "मोहरी", "हळद",
    "मिरची पावडर/मसाला", "सोयाबीन तेल", "मीठ", "भाजीपाला", "पूरक आहार",
    "सोया वडी", "गूळ / साखर", "दूध / दूध पावडर", "लाभार्थी नुसार होणारा खर्च",
  ];

  final List<int> dateRows = List.generate(31, (index) => index + 1);
  final Map<int, Map<String, String>> tableData = {};
  final Map<String, Map<String, String>> extraRows = {
    "मागील शिल्लक": {},
    "प्राप्त": {},
  };

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
    _initializeTable();
  }

  void _initializeTable() {
    for (var date in dateRows) {
      tableData[date] = {for (var col in columnHeaders) col: ""};
    }
    for (var row in extraRows.keys) {
      extraRows[row] = {for (var col in columnHeaders) col: ""};
    }
    _loadData();
    _loadExtraRowsFromVastuRecords();
  }

  Future<void> _loadExtraRowsFromVastuRecords() async {
    final query = await FirebaseFirestore.instance
        .collection('vastu_records')
        .doc(selectedMonth)
        .collection('items')
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final name = data['name'];
      if (columnHeaders.contains(name)) {
        if (data.containsKey('previous_stock')) {
          extraRows["मागील शिल्लक"]?[name] = data['previous_stock'].toString();
        }
        if (data.containsKey('received_this_month')) {
          extraRows["प्राप्त"]?[name] = data['received_this_month'].toString();
        }
      }
    }

    setState(() {});
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('poshan_data')
        .where('month', isEqualTo: selectedMonth)
        .get();

    for (var doc in snapshot.docs) {
      final dayStr = doc.id.replaceAll('day_', '');
      final day = int.tryParse(dayStr);
      if (day != null) {
        tableData[day] = Map<String, String>.from(doc.data()['data'] ?? {});
      }
    }

    final studentSnap = await FirebaseFirestore.instance.collection('students').get();
    final totalStudents = studentSnap.docs.length;
    for (var date in dateRows) {
      tableData[date]?["दैनिक उपस्थिती / लाभार्थी"] = totalStudents.toString();
    }

    final dailySnap = await FirebaseFirestore.instance.collection('dailyRecords').get();
    for (var doc in dailySnap.docs) {
      final data = doc.data();
      final date = DateTime.tryParse(data['date'] ?? '');
      if (date != null && months[date.month - 1] == selectedMonth) {
        final day = date.day;
        tableData[day]?["प्रत्यक्ष लाभार्थी ताटांची संख्या"] =
            (data['present'] ?? '').toString();
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'महिना निवडा',
                border: OutlineInputBorder(),
              ),
              items: months.map((month) {
                return DropdownMenuItem(value: month, child: Text(month));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedMonth = val;
                    _initializeTable();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (columnHeaders.length + 2) * 100,
                child: ListView.builder(
                  itemCount: dateRows.length + 4,
                  itemBuilder: (context, rowIndex) {
                    if (rowIndex == 0) {
                      return Row(
                        children: [
                          cell("दिनांक", isHeader: true, isCorner: true),
                          ...columnHeaders.map((header) => cell(header, isHeader: true)),
                          cell("कृती", isHeader: true),
                        ],
                      );
                    } else if (rowIndex == 1 || rowIndex == 2) {
                      final label = rowIndex == 1 ? "मागील शिल्लक" : "प्राप्त";
                      return Row(
                        children: [
                          cell(label, isHeader: true),
                          ...columnHeaders.map((col) => textCell(
                                extraRows[label]?[col] ?? "",
                                editable: true,
                                onChanged: (val) => extraRows[label]?[col] = val,
                              )),
                          cell("—"),
                        ],
                      );
                    } else if (rowIndex == dateRows.length + 2) {
                      return Row(
                        children: [
                          cell("वापरलेले", isHeader: true),
                          ...columnHeaders.map((col) {
                            double total = 0;
                            for (var date in dateRows) {
                              total += double.tryParse(tableData[date]?[col] ?? '') ?? 0;
                            }
                            return cell(total.toStringAsFixed(2));
                          }),
                          cell("—"),
                        ],
                      );
                    } else if (rowIndex == dateRows.length + 3) {
                      return Row(
                        children: [
                          cell("शिल्लक", isHeader: true),
                          ...columnHeaders.map((col) {
                            final previous = double.tryParse(extraRows["मागील शिल्लक"]?[col] ?? '') ?? 0;
                            final received = double.tryParse(extraRows["प्राप्त"]?[col] ?? '') ?? 0;
                            double used = 0;
                            for (var date in dateRows) {
                              used += double.tryParse(tableData[date]?[col] ?? '') ?? 0;
                            }
                            final balance = previous + received - used;
                            return cell(balance.toStringAsFixed(2));
                          }),
                          cell("—"),
                        ],
                      );
                    } else {
                      final date = dateRows[rowIndex - 3];
                      return Row(
                        children: [
                          cell(date.toString()),
                          ...columnHeaders.map((col) => textCell(tableData[date]?[col] ?? "")),
                          actionCell(date),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cell(String text, {bool isHeader = false, bool isCorner = false}) {
    return Container(
      width: 100,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: isCorner
            ? Colors.deepPurple.shade100
            : isHeader
                ? Colors.deepPurple.shade100
                : null,
      ),
      child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget textCell(String value, {bool editable = false, void Function(String)? onChanged}) {
    return Container(
      width: 100,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: editable
          ? TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              decoration: const InputDecoration(border: InputBorder.none),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            )
          : Text(value.isEmpty ? "-" : value),
    );
  }

  Widget actionCell(int date) {
    return Container(
      width: 100,
      height: 48,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
            onPressed: () => _openEditDialog(date),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(int date) {
    final controllers = {
      for (var col in columnHeaders)
        col: TextEditingController(text: tableData[date]?[col] ?? "")
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("संपादन - दिनांक $date"),
        content: SingleChildScrollView(
          child: Column(
            children: columnHeaders.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: controllers[col],
                  decoration: InputDecoration(labelText: col),
                  keyboardType: TextInputType.number,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              for (var col in columnHeaders) {
                tableData[date]![col] = controllers[col]!.text.trim();
              }

              await FirebaseFirestore.instance
                  .collection('poshan_data')
                  .doc('day_$date')
                  .set({
                'month': selectedMonth,
                'data': tableData[date],
              });

              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
