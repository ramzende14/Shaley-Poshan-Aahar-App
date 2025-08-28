// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously, avoid_types_as_parameter_names, avoid_print, prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zp/pages/admin_edit_teacher_page.dart';
import 'package:zp/pages/admin_app_drawer.dart';

class AdminListTeacherPage extends StatefulWidget {
  final String adminType;
  const AdminListTeacherPage({super.key, required this.adminType});

  @override
  _AdminListTeacherPageState createState() => _AdminListTeacherPageState();
}

class _AdminListTeacherPageState extends State<AdminListTeacherPage> {
  String searchQuery = "";
  int totalTeachers = 0;

  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Stream<QuerySnapshot> teacherStream =
      FirebaseFirestore.instance.collection('admins').snapshots();

  @override
  void initState() {
    super.initState();
    _fetchTeacherCount();
  }

  Future<void> _fetchTeacherCount() async {
    var snapshot = await _firestore.collection('admins').get();
    setState(() {
      totalTeachers = snapshot.docs.length;
    });
  }

  void deleteUser(String id) async {
    await _firestore.collection('admins').doc(id).delete();
    _fetchTeacherCount();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teacher deleted successfully!')),
    );
  }

  Future<String> getImageUrl(String path) async {
    try {
      // Ensure the path is correctly formatted for Firebase
      String formattedPath = path.replaceAll("%2F", "/").replaceAll("%3A", ":");
      return formattedPath;
    } catch (e) {
      print("🔥 Error formatting image URL: $e");
      return ''; // Return empty string in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onSelectPage: (Widget) {},
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// ✅ TOP TEACHER COUNT TEXT
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
                "Total Teachers: $totalTeachers",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// 🔍 Search Field
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
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
                      hintText: 'Search by Name or Email',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: teacherStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  String search = searchQuery.toLowerCase();

                  final List<Map<String, dynamic>> teachers =
                      snapshot.data!.docs
                          .map((doc) => {
                                ...doc.data() as Map<String, dynamic>,
                                'id': doc.id,
                              })
                          .where((teacher) {
                    bool matchesSearch =
                        (teacher['fullName']?.toString().toLowerCase() ?? '')
                                .contains(search) ||
                            (teacher['email']?.toLowerCase() ?? '')
                                .contains(search);
                    return matchesSearch;
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 600),
                      child: DataTable(
                        columnSpacing: 30.0,
                        headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text('Actions')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('User Name')),
                          DataColumn(label: Text('addharNo')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Class')),
                          DataColumn(label: Text('Password')),
                          DataColumn(label: Text('Photo')),
                        ],
                        rows: teachers.map((teacher) {
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
                                            AdminEditTeacherPage(
                                          teacherId: teacher['id'],                                          
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => deleteUser(teacher['id']),
                                ),
                              ],
                            )),
                            DataCell(Text(teacher['fullName'] ?? 'No Name')),
                            DataCell(
                                Text(teacher['userName'] ?? 'No User Name')),
                            DataCell(
                              Text(
                                teacher['addharNo'] ?? 'No addhar Number',
                              ),
                            ),
                            DataCell(Text(teacher['email'] ?? 'No Email')),
                            DataCell(Text(teacher['adminType'] ?? 'No Type')),
                            DataCell(
                                Text(teacher['password'] ?? 'No Password')),
                            DataCell(
                              teacher['imageUrl'] != null &&
                                      teacher['imageUrl'].isNotEmpty
                                  ? ClipOval(
                                      child: Container(
                                        width: 120, // Circle width
                                        height: 120, // Circle height
                                        decoration: BoxDecoration(
                                          shape: BoxShape
                                              .circle, // Ensures the container is a perfect circle
                                        ),
                                        child: Image.network(
                                          teacher['imageUrl'],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
