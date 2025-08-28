// ignore_for_file: avoid_print, unused_element, await_only_futures, prefer_final_fields, file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminListAttendanceStudentPage extends StatefulWidget {
  const AdminListAttendanceStudentPage({super.key, required String studentEmail, required String studentId});

  @override
  State<AdminListAttendanceStudentPage> createState() =>
      _AdminListAttendanceStudentPageState();
}

class _AdminListAttendanceStudentPageState
    extends State<AdminListAttendanceStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, dynamic>> _students = [];
  Map<String, String> _homework = {};
  bool _isLoading = false;

  String? selectedClass = "Select Class";
  List<String> classList = ["Select Class"];
  bool _showCalendar = false;
  String? _calendarStudentId;

  final TextEditingController _searchController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchClassList();
    _fetchAndAutoMarkAttendance();
  }

  Future<void> _fetchClassList() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
    });
  }

  Future<void> _fetchAndAutoMarkAttendance() async {
    setState(() => _isLoading = true);

    try {
      final studentSnapshot = await _firestore.collection('students').get();
      final attendanceSnapshot = await _firestore
          .collection('studentAttendance')
          .doc(_selectedDate)
          .get();

      Map<String, dynamic> existingAttendance = {};
      if (attendanceSnapshot.exists) {
        existingAttendance = attendanceSnapshot.data() as Map<String, dynamic>;
      }

      _students = studentSnapshot.docs.map((doc) {
        final data = doc.data();
        final studentId = doc.id;

        // Set default status to Present if not marked already
        if (!existingAttendance.containsKey(studentId)) {
          _homework[studentId] = 'Present';
        } else {
          _homework[studentId] =
              existingAttendance[studentId]['status'].toString();
        }

        return {
          'id': studentId,
          'fullName': data['fullName'] ?? '',
          'className': data['class'] ?? '',
        };
      }).toList();

      // Save auto-marked Present status to Firestore (only new ones)
      final newAttendanceData = <String, dynamic>{};
      _homework.forEach((id, status) {
        newAttendanceData[id] = {'status': status};
      });

      await _firestore
          .collection('studentAttendance')
          .doc(_selectedDate)
          .set(newAttendanceData, SetOptions(merge: true));
    } catch (e) {
      print("❌ Error fetching or auto-marking attendance: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateAttendance(String id, String status) async {
    // _homework[id] = status;

    // Map<String, dynamic> formattedHomework = {};
    // _homework.forEach((id, status) {
    //   formattedHomework[id] = {
    //     'status': status, // Keep this as a map to store properly in Firestore
    //   };
    // });

    await _firestore
        .collection('studentAttendance')
        .doc(_selectedDate);
        //.set(formattedHomework);

    setState(() {});
  }

  Widget _buildStatusIcon(String studentId, DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('studentAttendance').doc(dateKey).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status =
            data[studentId] != null ? data[studentId]['status'] : null;

        if (status == 'Present') {
          return const Icon(Icons.check_circle, color: Colors.green, size: 18);
        } else if (status == 'Absent') {
          return const Icon(Icons.cancel, color: Colors.red, size: 18);
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔼 TOP CALENDAR FOR SELECTING DATE
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCalendar = !_showCalendar;
                      _calendarStudentId = null;
                    });
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ).createShader(bounds),
                    child:
                        const Icon(Icons.calendar_today, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_showCalendar && _calendarStudentId == null)
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                focusedDay: DateTime.parse(_selectedDate),
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) =>
                    _selectedDate == DateFormat('yyyy-MM-dd').format(day),
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate =
                        DateFormat('yyyy-MM-dd').format(selectedDay);
                    _showCalendar = false;
                  });
                  _fetchAndAutoMarkAttendance();
                },
              ),

            const SizedBox(height: 10),

            // 🔍 SEARCH AND CLASS DROPDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
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
                        hintText: 'Search by Name',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: DropdownButtonFormField<String>(
                      value: selectedClass,
                      items: classList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🗓 STUDENT SPECIFIC CALENDAR
            if (_calendarStudentId != null)
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                focusedDay: DateTime.now(),
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => false,
                onDaySelected: (day, _) {
                  setState(() => _calendarStudentId = null);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('studentAttendance')
                          .doc(DateFormat('yyyy-MM-dd').format(day))
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final status = data[_calendarStudentId] != null
                            ? data[_calendarStudentId]['status']
                            : null;

                        Color textColor = Colors.black;
                        if (status == 'Present') {
                          textColor = Colors.green;
                        } else if (status == 'Absent') {
                          textColor = Colors.red;
                        }

                        return Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // 🧾 STUDENT LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final id = student['id'];
                        final fullName = student['fullName'];
                        final className = student['className'];
                        final status = _homework[id] ?? 'Present';

                        if (_searchController.text.isNotEmpty &&
                            !fullName.toLowerCase().contains(
                                _searchController.text.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        if (selectedClass != "Select Class" &&
                            className != selectedClass) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          color: status == "Absent" ? Colors.red[100] : null,
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$fullName ($className)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: status == "Absent"
                                              ? Colors.red[900]
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_month,
                                          color: Colors.indigo),
                                      onPressed: () {
                                        setState(() => _calendarStudentId = id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    //const Text("Homework:"),
                                    DropdownButton<String>(
                                      value: status,
                                      items: ['Present', 'Absent']
                                          .map((value) => DropdownMenuItem(
                                                value: value,
                                                child: Text(value),
                                              ))
                                          .toList(),
                                      onChanged: (newStatus) {
                                        _updateAttendance(id, newStatus!);
                                      },
                                    ),
                                  ],
                                ),
                              ],
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