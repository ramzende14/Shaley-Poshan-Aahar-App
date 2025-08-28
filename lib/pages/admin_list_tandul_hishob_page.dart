// ignore_for_file: unused_import, use_key_in_widget_constructors, prefer_const_constructors, sort_child_properties_last, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zp/pages/admin_add_tandulentery_page.dart';
import 'package:zp/pages/admin_edit_tandulentery.dart';

class TandulHishobPage extends StatefulWidget {
  @override
  State<TandulHishobPage> createState() => _TandulHishobPageState();
}

class _TandulHishobPageState extends State<TandulHishobPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int studentCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStudentCount();
  }

  Future<void> _fetchStudentCount() async {
    final snapshot = await _firestore.collection('students').get();
    setState(() {
      studentCount = snapshot.docs.length;
    });
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("नोंद हटवा"),
        content: Text("आपण ही नोंद हटवू इच्छिता?"),
        actions: [
          TextButton(
            child: Text("रद्द"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("हो"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('tandul_entries').doc(id).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("नोंद हटवली गेली")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0), // 1.5cm padding (top & bottom)
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('tandul_entries').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("त्रुटी आली आहे."));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(child: Text("नोंदी नाहीत"));
            }

            // Month order list
            final List<String> monthOrder = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];

            // Current month
            final currentMonth = monthOrder[DateTime.now().month - 1];

            // Custom sorting
            docs.sort((a, b) {
              final aMonth = (a['month'] ?? '') as String;
              final bMonth = (b['month'] ?? '') as String;

              if (aMonth == currentMonth) return -1;
              if (bMonth == currentMonth) return 1;

              return monthOrder.indexOf(bMonth).compareTo(monthOrder.indexOf(aMonth));
            });

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Table surrounding padding
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey),
                      headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade100),
                      columns: const [
                        DataColumn(label: Text('महिना', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('दिनांक', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('विद्यार्थी', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('मागील महिन्याचा शिल्लक (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('चालू महिन्याचा प्राप्त (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('वापरलेला तांदूळ (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('एकूण (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('क्रिया', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final id = doc.id;

                        return DataRow(cells: [
                          DataCell(Text(data['month'] ?? '')),
                          DataCell(Text(data['date'] ?? '')),
                          DataCell(Text('$studentCount')),
                          DataCell(Text('${data['stock'] ?? 0}')),
                          DataCell(Text('${data['received'] ?? 0}')),
                          DataCell(Text('${data['used'] ?? 0}')),
                          DataCell(Text('${data['total'] ?? 0}')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditTandulEntryPage(
                                        id: id,
                                        existingData: data,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, id),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
