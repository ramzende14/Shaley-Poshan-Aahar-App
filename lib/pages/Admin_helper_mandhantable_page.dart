// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelperMandanTable extends StatelessWidget {
  final String helperName;

  const HelperMandanTable({super.key, required this.helperName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mandan_reports')
          .where('helper_name', isEqualTo: helperName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("कोणताही अहवाल आढळला नाही."));
        }

        final docs = snapshot.data!.docs;

        return SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16), // Equal left-right padding
    child: Table(
      defaultColumnWidth: const FixedColumnWidth(120.0),
      border: TableBorder.all(color: Colors.grey, width: 1),
      
      children: [
        TableRow(
          //decoration: const BoxDecoration(color: Colors.white),
          decoration: BoxDecoration(color: Colors.deepPurple.shade100),

          
          children: [
            _tableHeaderCell("महिना"),
            _tableHeaderCell("कार्यदिन"),
            _tableHeaderCell("१ ते ८ पटसंख्या"),
            _tableHeaderCell("पत्ता"),
            _tableHeaderCell("संवर्ग"),
            _tableHeaderCell("आधार क्रमांक"),
            _tableHeaderCell("रक्कम"),
            _tableHeaderCell("खाते क्रमांक"),
            _tableHeaderCell("क्रिया"),
          ],
        ),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return TableRow(children: [
            _tableCell(data['month'] ?? ''),
            _tableCell("${data['workDays'] ?? ''}"),
            _tableCell("${data['count18'] ?? ''}"),
            _tableCell(data['address'] ?? ''),
            _tableCell(data['category'] ?? ''),
            _tableCell(data['aadhar'] ?? ''),
            _tableCell("₹${data['amount'] ?? ''}"),
            _tableCell(data['bankAccount'] ?? ''),
            TableCell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditDialog(context, doc.id, data);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('mandan_reports')
                          .doc(doc.id)
                          .delete();
                    },
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ],
    ),
  ),
);

      },
    );
  }

  static Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(text)),
    );
  }

  static void showAddEntryDialog(BuildContext context, String helperName) {
    _showEntryDialog(context, helperName);
  }

  static void _showEditDialog(
      BuildContext context, String docId, Map<String, dynamic> oldData) {
    _showEntryDialog(
      context,
      oldData['helper_name'],
      docId: docId,
      existingData: oldData,
    );
  }

  static void _showEntryDialog(
    BuildContext context,
    String helperName, {
    String? docId,
    Map<String, dynamic>? existingData,
  }) {
    final monthController =
        TextEditingController(text: existingData?['month'] ?? '');
    final daysController = TextEditingController(
        text: existingData?['workDays']?.toString() ?? '');
    final countController = TextEditingController(
        text: existingData?['count18']?.toString() ?? '');
    final addressController =
        TextEditingController(text: existingData?['address'] ?? '');
    final categoryController =
        TextEditingController(text: existingData?['category'] ?? '');
    final aadharController =
        TextEditingController(text: existingData?['aadhar'] ?? '');
    final amountController = TextEditingController(
        text: existingData?['amount']?.toString() ?? '');
    final bankController =
        TextEditingController(text: existingData?['bankAccount'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "नवीन नोंद" : "नोंद संपादित करा"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: monthController,
                decoration: const InputDecoration(labelText: 'महिना'),
              ),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'कार्यदिन'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: countController,
                decoration:
                    const InputDecoration(labelText: '१ ते ८ ची पटसंख्या'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'पत्ता'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'संवर्ग'),
              ),
              TextField(
                controller: aadharController,
                decoration: const InputDecoration(labelText: 'आधार क्रमांक'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'रक्कम'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bankController,
                decoration:
                    const InputDecoration(labelText: 'बँक खाते क्रमांक'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final data = {
                'helper_name': helperName,
                'month': monthController.text,
                'workDays': int.tryParse(daysController.text) ?? 0,
                'count18': int.tryParse(countController.text) ?? 0,
                'address': addressController.text,
                'category': categoryController.text,
                'aadhar': aadharController.text,
                'amount': double.tryParse(amountController.text) ?? 0.0,
                'bankAccount': bankController.text,
              };

              if (docId == null) {
                await FirebaseFirestore.instance
                    .collection('mandan_reports')
                    .add(data);
              } else {
                await FirebaseFirestore.instance
                    .collection('mandan_reports')
                    .doc(docId)
                    .update(data);
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
