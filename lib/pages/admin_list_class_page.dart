
// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zp/pages/admin_app_drawer.dart';
import 'package:zp/pages/admin_edit_class_page.dart';

class AdminListClassPage extends StatefulWidget {
  const AdminListClassPage({super.key,  });

  @override
  // ignore: library_private_types_in_public_api
  _AdminListClassPageState createState() => _AdminListClassPageState();
}

class _AdminListClassPageState extends State<AdminListClassPage> {
  final Stream<QuerySnapshot> studentsStream =
      FirebaseFirestore.instance.collection('class').snapshots();

  // App bar hover state
  Color appBarTitleColor = Colors.white;
  Color backArrowColor = Colors.white;
  Color addClassTextColor = Colors.white;

  void deleteUser(String id) {
    FirebaseFirestore.instance.collection('class').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: studentsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List storedocs =
            snapshot.data!.docs.map((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          data['id'] = document.id;
          return data;
        }).toList();

        return Scaffold(
          // ignore: non_constant_identifier_names
          drawer: AppDrawer(
            // ignore: non_constant_identifier_names
            onSelectPage: (Widget) {}, 
          ), // Added the drawer
          body: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(),
                columnWidths: const <int, TableColumnWidth>{
                  1: FixedColumnWidth(140),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      tableHeader('Class'),
                      tableHeader('Action'),
                    ],
                  ),
                  for (var i = 0; i < storedocs.length; i++)
                    TableRow(
                      children: [
                        tableCell(storedocs[i]['name'] ?? 'No Name'),
                        actionCell(
                          onEdit: () {
                            // Navigate to the AdminEditStudentPage with the student's ID
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminEditClassPage(
                                  classId: storedocs[i]['id'],
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            deleteUser(storedocs[i]['id']);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableCell tableHeader(String text) {
    return TableCell(
      child: Container(
        color: const Color.fromARGB(255, 244, 247, 244), // Dark background
        padding:
            const EdgeInsets.symmetric(vertical: 10.0), // Add vertical padding
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 13, 13, 13), // Text color
              fontWeight: FontWeight.bold,
              fontSize: 18.0, // Slightly larger font size for better appearance
            ),
          ),
        ),
      ),
    );
  }

  TableCell tableCell(String text) {
    return TableCell(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }

  TableCell actionCell(
      {required VoidCallback onEdit, required VoidCallback onDelete}) {
    return TableCell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onEdit,
            icon:
                const Icon(Icons.edit, color: Color.fromARGB(255, 75, 172, 64)),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}



