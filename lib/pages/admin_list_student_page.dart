// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously, avoid_types_as_parameter_names, avoid_print, prefer_const_constructors, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zp/pages/admin_app_drawer.dart';
import 'package:zp/pages/admin_edit_student_page.dart';

class AdminListStudentPage extends StatefulWidget {
  final String adminType;
  const AdminListStudentPage({super.key, required this.adminType});

  @override
  _AdminListStudentPageState createState() => _AdminListStudentPageState();
}

class _AdminListStudentPageState extends State<AdminListStudentPage> {
  String searchQuery = "";
  String? selectedClass = "Selecte Class";
  List<String> classList = ["Selecte Class"];
  Map<String, int> classCounts = {};
  int totalStudents = 0;

  int pageSize = 10;
  DocumentSnapshot? lastDocument;
  DocumentSnapshot? firstDocument;
  bool hasNext = true;
  bool hasPrev = false;
  List<DocumentSnapshot> currentDocs = [];

  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchStudentCounts();
    _fetchPage();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(classSnapshot.docs.map((doc) => doc['name'] as String));
    });
  }

  Future<void> _fetchStudentCounts() async {
    var snapshot = await _firestore.collection('students').get();
    Map<String, int> counts = {};
    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final className = data['class'] ?? 'Unknown';
      counts[className] = (counts[className] ?? 0) + 1;
      total++;
    }
    setState(() {
      classCounts = counts;
      totalStudents = total;
    });
  }

  Future<void> _fetchPage({bool next = true}) async {
    Query query = _firestore.collection('students').orderBy('fullName');

    if (selectedClass != "Selecte Class") {
      query = query.where('class', isEqualTo: selectedClass);
    }

    if (next && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!).limit(pageSize);
    } else if (!next && firstDocument != null) {
      query = query.endBeforeDocument(firstDocument!).limitToLast(pageSize);
    } else {
      query = query.limit(pageSize);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    setState(() {
      currentDocs = docs;
      if (docs.isNotEmpty) {
        firstDocument = docs.first;
        lastDocument = docs.last;
      }
      hasNext = docs.length == pageSize;
      hasPrev = firstDocument != null;
    });
  }

  void _onSearchOrClassChanged() {
    setState(() {
      lastDocument = null;
      firstDocument = null;
      _fetchPage();
    });
  }

 
   void deleteUser(String id) async {
    await FirebaseFirestore.instance.collection('students').doc(id).delete();
    _fetchStudentCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student deleted successfully!')),
    );
  }
  @override
  Widget build(BuildContext context) {
    String countText;
    if (selectedClass == "Selecte Class") {
      countText = "Total Students: $totalStudents";
    } else {
      countText =
          "$selectedClass Class Students: ${classCounts[selectedClass] ?? 0}";
    }


    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelectPage: (Widget) {}),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                countText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Email',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),

                // Dropdown
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple]),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    items: classList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedClass = newValue!;
                      });
                    },
                    isExpanded: true,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    menuMaxHeight: 200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                     DataColumn(label: Text('Actions')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('User Name')),
                            DataColumn(label: Text('addharNo')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Student Number')),
                            DataColumn(label: Text('parent\'s Number')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Password')),
                            DataColumn(label: Text('Photo')),
                  ],
                  rows: currentDocs.map((doc) {
                    final student = doc.data() as Map<String, dynamic>;
                       return DataRow(cells: [
                              DataCell(Row(
                                children: [
                                   IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,  
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminEditStudentPage(
                                            studentId: doc.id,
                                            
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () => deleteUser(doc.id),
                                  ),
                                ],
                              )),
                              DataCell(Text(student['fullName'] ?? 'No Name')),
                              DataCell(
                                  Text(student['userName'] ?? 'No User Name')),
                              DataCell(
                                Text(
                                  student['addharNo'] ?? 'No addhar Number',
                                ),
                              ),
                              DataCell(Text(student['email'] ?? 'No Email')),
                              DataCell(Text(student['studentphoneNumber'] ??
                                  'No  Number')),
                              DataCell(Text(student['parentsphoneNumber'] ??
                                  'No  Number')),
                              DataCell(Text(student['class'] ?? 'No Class')),
                              DataCell(
                                  Text(student['password'] ?? 'No Password')),
                              DataCell(
                                student['imageUrl'] != null &&
                                        student['imageUrl'].isNotEmpty
                                    ? ClipOval(
                                        child: Container(
                                          width: 120, // Circle width
                                          height: 120, // Circle height
                                          decoration: BoxDecoration(
                                            shape: BoxShape
                                                .circle, // Ensures the container is a perfect circle
                                          ),
                                          child: Image.network(
                                            student['imageUrl'],
                                            fit: BoxFit
                                                .contain, // Ensures the whole image is shown without cropping
                                            alignment: Alignment.center,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null) {
                                                return child;
                                              } else {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(), // Loading indicator
                                                );
                                              }
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.broken_image,
                                                color: Colors
                                                    .grey, // Placeholder icon for broken images
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.broken_image,
                                        color: Colors
                                            .grey, // Placeholder icon for missing images
                                      ),
                              ),
                            ]);
                           }).toList(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: hasPrev ? () => _fetchPage(next: false) : null,
                  child: Text('<'),
                ),
                ElevatedButton(
                  onPressed: hasNext ? () => _fetchPage(next: true) : null,
                  child: Text('>'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
