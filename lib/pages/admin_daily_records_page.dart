// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecordTable extends StatelessWidget {
  const DailyRecordTable({super.key});

  Future<void> _editRecord(BuildContext context, String docId, Map<String, dynamic> data) async {
    final dateController = TextEditingController(text: data['date'] ?? '');
    final dayController = TextEditingController(text: data['day'] ?? '');
    final presentController = TextEditingController(text: data['present']?.toString() ?? '');
    final lastMonthStockController = TextEditingController(text: data['lastMonthStock']?.toString() ?? '');
    final receivedThisMonthController = TextEditingController(text: data['receivedThisMonth']?.toString() ?? '');
    final totalRiceController = TextEditingController(text: data['totalRice']?.toString() ?? '');
    final beneficiaryCountController = TextEditingController(text: data['beneficiaryCount']?.toString() ?? '');
    final totalCookedRiceController = TextEditingController(text: data['totalCookedRice']?.toString() ?? '');
    final endMonthRemainingRiceController = TextEditingController(text: data['endMonthRemainingRice']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("नोंद संपादन करा"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: "तारीख (yyyy-MM-dd)"),
              ),
              TextField(
                controller: dayController,
                decoration: const InputDecoration(labelText: "वार"),
              ),
              TextField(
                controller: presentController,
                decoration: const InputDecoration(labelText: "पटसंख्या"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: lastMonthStockController,
                decoration: const InputDecoration(labelText: "मागील महिना शिल्लक तांदूळ"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: receivedThisMonthController,
                decoration: const InputDecoration(labelText: "चालू महिना प्राप्त तांदूळ"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: totalRiceController,
                decoration: const InputDecoration(labelText: "एकूण तांदूळ"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: beneficiaryCountController,
                decoration: const InputDecoration(labelText: "लाभार्थी संख्या"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: totalCookedRiceController,
                decoration: const InputDecoration(labelText: "शिजवलेला सर्व तांदूळ"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: endMonthRemainingRiceController,
                decoration: const InputDecoration(labelText: "महिना अखेर शिल्लक तांदूळ"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("रद्द"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("सेव्ह"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('dailyRecords').doc(docId).update({
                'date': dateController.text.trim(),
                'day': dayController.text.trim(),
                'present': int.tryParse(presentController.text.trim()) ?? 0,
                'lastMonthStock': double.tryParse(lastMonthStockController.text.trim()) ?? 0,
                'receivedThisMonth': double.tryParse(receivedThisMonthController.text.trim()) ?? 0,
                'totalRice': double.tryParse(totalRiceController.text.trim()) ?? 0,
                'beneficiaryCount': int.tryParse(beneficiaryCountController.text.trim()) ?? 0,
                'totalCookedRice': double.tryParse(totalCookedRiceController.text.trim()) ?? 0,
                'endMonthRemainingRice': double.tryParse(endMonthRemainingRiceController.text.trim()) ?? 0,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("नोंद हटवायची आहे का?"),
        content: const Text("ही नोंद कायमची हटवली जाईल."),
        actions: [
          TextButton(child: const Text("रद्द"), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("हटवा"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      await FirebaseFirestore.instance.collection('dailyRecords').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0), // 1.5cm vertical padding
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('dailyRecords').orderBy('date').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data!.docs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DataTable(
                        border: TableBorder.all(color: Colors.black54, width: 1),
                        headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade100),
                        columnSpacing: 18.0,
                        columns: const [
                          DataColumn(label: Text('तारीख')),
                          DataColumn(label: Text('वार')),
                          DataColumn(label: Text('पटसंख्या')),
                          DataColumn(label: Text('मागील महिना\nशिल्लक तांदूळ')),
                          DataColumn(label: Text('चालू महिना\nप्राप्त तांदूळ')),
                          DataColumn(label: Text('एकूण तांदूळ')),
                          DataColumn(label: Text('लाभार्थी संख्या')),
                          DataColumn(label: Text('शिजवलेला\nसर्व तांदूळ')),
                          DataColumn(label: Text('महिना अखेर\nशिल्लक तांदूळ')),
                          DataColumn(label: Text('सही')),
                          DataColumn(label: Text('Edit')),
                          DataColumn(label: Text('Delete')),
                        ],
                        rows: records.map((record) {
                          final data = record.data() as Map<String, dynamic>;
                          final docId = record.id;

                          String formattedDate = '';
                          if (data.containsKey('date') && data['date'] != null) {
                            try {
                              final parsedDate = DateTime.parse(data['date']);
                              formattedDate =
                                  "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
                            } catch (_) {
                              formattedDate = '';
                            }
                          }

                          return DataRow(cells: [
                            DataCell(Text(formattedDate)),
                            DataCell(Text(data['day'] ?? '')),
                            DataCell(Text('${data['present'] ?? ''}')),
                            DataCell(Text('${data['lastMonthStock'] ?? ''}')),
                            DataCell(Text('${data['receivedThisMonth'] ?? ''}')),
                            DataCell(Text('${data['totalRice'] ?? ''}')),
                            DataCell(Text('${data['beneficiaryCount'] ?? ''}')),
                            DataCell(Text('${data['totalCookedRice'] ?? ''}')),
                            DataCell(Text('${data['endMonthRemainingRice'] ?? ''}')),
                            DataCell(Icon(
                              data['headMasterSign'] == true ? Icons.check : Icons.close,
                              color: data['headMasterSign'] == true ? Colors.green : Colors.red,
                            )),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editRecord(context, docId, data),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRecord(context, docId),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
