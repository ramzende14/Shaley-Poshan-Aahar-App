// ignore_for_file: use_super_parameter, use_super_parameters, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zp/pages/admin_add_vastu_page.dart';

class VastuncheRecord extends StatefulWidget {
  final String selectedMonth;
  const VastuncheRecord({Key? key, required this.selectedMonth}) : super(key: key);

  @override
  State<VastuncheRecord> createState() => _VastuncheRecordState();
}

class _VastuncheRecordState extends State<VastuncheRecord> {
  CollectionReference getCollectionForMonth([String? month]) {
    return FirebaseFirestore.instance
        .collection('vastu_records')
        .doc(month ?? widget.selectedMonth)
        .collection('items');
  }

  String getPreviousMonth(String currentMonth) {
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    int index = months.indexOf(currentMonth);
    if (index <= 0) return months.last;
    return months[index - 1];
  }

  Future<void> updateFromPreviousMonth() async {
    final currentCollection = getCollectionForMonth();
    final previousMonth = getPreviousMonth(widget.selectedMonth);
    final previousCollection = getCollectionForMonth(previousMonth);

    final previousSnapshot = await previousCollection.get();
    final currentSnapshot = await currentCollection.get();

    final Map<String, String> previousRemainingMap = {
      for (var doc in previousSnapshot.docs)
        (doc.data() as Map<String, dynamic>)['name']: (doc.data() as Map<String, dynamic>)['remaining'] ?? '0'
    };

    for (var doc in currentSnapshot.docs) {
      final currentData = doc.data() as Map<String, dynamic>;
      final name = currentData['name'];
      final prevStock = int.tryParse(previousRemainingMap[name] ?? '0') ?? 0;
      final received = int.tryParse(currentData['received_this_month'] ?? '0') ?? 0;
      final total = prevStock + received;
      final used = int.tryParse(currentData['used'] ?? '0') ?? 0;
      final remaining = total - used;

      await currentCollection.doc(doc.id).update({
        'previous_stock': prevStock.toString(),
        'total': total.toString(),
        'remaining': remaining.toString(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('मागील महिन्यातून डेटा अपडेट झाला आहे.')),
    );
  }

  void _editDialog(BuildContext context, String docId, Map<String, dynamic>? existingData) {
    final fields = {
      'previous_stock': TextEditingController(text: existingData?['previous_stock'] ?? ''),
      'received_this_month': TextEditingController(text: existingData?['received_this_month'] ?? ''),
      'used': TextEditingController(text: existingData?['used'] ?? ''),
      'next_month_demand': TextEditingController(text: existingData?['next_month_demand'] ?? ''),
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('नोंद संपादन करा'),
        content: SingleChildScrollView(
          child: Column(
            children: fields.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("रद्द")),
          ElevatedButton(
            onPressed: () async {
              final prev = int.tryParse(fields['previous_stock']!.text) ?? 0;
              final recv = int.tryParse(fields['received_this_month']!.text) ?? 0;
              final used = int.tryParse(fields['used']!.text) ?? 0;
              final total = prev + recv;
              final remaining = total - used;

              await getCollectionForMonth().doc(docId).update({
                'previous_stock': prev.toString(),
                'received_this_month': recv.toString(),
                'used': used.toString(),
                'total': total.toString(),
                'remaining': remaining.toString(),
                'next_month_demand': fields['next_month_demand']!.text
              });

              Navigator.pop(context);
            },
            child: const Text("जतन करा"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: updateFromPreviousMonth,
              icon: const Icon(Icons.sync),
              label: const Text("मागील शिल्लक अपडेट करा"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCollectionForMonth().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("त्रुटी आली आहे"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("डेटा उपलब्ध नाही."));
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(color: Colors.black54),
                          headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade100),
                          columnSpacing: 25,
                          columns: const [
                            DataColumn(label: Text('नाव')),
                            DataColumn(label: Text('मागील शिल्लक')),
                            DataColumn(label: Text('प्राप्त')),
                            DataColumn(label: Text('एकूण')),
                            DataColumn(label: Text('वापरले')),
                            DataColumn(label: Text('शिल्लक')),
                            DataColumn(label: Text('मागणी')),
                            DataColumn(label: Text('क्रिया')),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id;

                            return DataRow(
                              cells: [
                                DataCell(Text(data['name'] ?? '')),
                                DataCell(Text(data['previous_stock'] ?? '0')),
                                DataCell(Text(data['received_this_month'] ?? '0')),
                                DataCell(Text(data['total'] ?? '0')),
                                DataCell(Text(data['used'] ?? '0')),
                                DataCell(Text(data['remaining'] ?? '0')),
                                DataCell(Text(data['next_month_demand'] ?? '0')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _editDialog(context, id, data),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddVastuEntryDialog(selectedMonth: widget.selectedMonth),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurple,
        tooltip: 'नवीन नोंद जोडा',
      ),
    );
  }
}
