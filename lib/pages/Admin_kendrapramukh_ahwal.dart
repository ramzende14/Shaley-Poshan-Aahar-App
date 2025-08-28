// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zp/pages/admin_vastu_details_forkendrpramukhahwal.dart';

class CombinedInfoBoxPage extends StatefulWidget {
  const CombinedInfoBoxPage({super.key});

  @override
  State<CombinedInfoBoxPage> createState() => _CombinedInfoBoxPageState();
}

class _CombinedInfoBoxPageState extends State<CombinedInfoBoxPage> {
  String schoolName = "Z.P. Primary School";
  String group = "Karjat Center";
  String taluka = "Karjat";
  String district = "Ahmednagar";
  String totalStudents = "-";
  String takingMeal = "112";
  String notTakingMeal = "8";
  String workingDays = "20";
  String cookDays = "18";

  String riceDate = "";
  String grainsDate = "";

  final riceReceiptController = TextEditingController();
  final grainsReceiptController = TextEditingController();

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  String selectedMonth = "July";

  @override
  void initState() {
    super.initState();
    fetchTotalStudentsFromStudentsCollection();
  }

  Future<void> fetchTotalStudentsFromStudentsCollection() async {
    try {
      final studentSnap = await FirebaseFirestore.instance.collection('students').get();
      final total = studentSnap.docs.length;

      setState(() {
        totalStudents = total.toString();
      });
    } catch (e) {
      print("Error fetching students count: $e");
    }
  }

  Future<void> selectDate(bool isRice) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        if (isRice) {
          riceDate = formatted;
        } else {
          grainsDate = formatted;
        }
      });
    }
  }

  Widget infoItem(String label, String value, {bool isDate = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: isDate
                ? InkWell(
                    onTap: onTap,
                    child: Text(
                      value.isEmpty ? "तारीख निवडा" : value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text("महिना निवडा:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedMonth,
                  borderRadius: BorderRadius.circular(10),
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  dropdownColor: Colors.blue.shade50,
                  items: months.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMonth = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isMobile ? buildMobileLayout() : buildTabletLayout(),
            ),

            const SizedBox(height: 20),

            // 🔁 FIX: Add ValueKey to force rebuild on month change
            VastuReadOnlyTable(key: ValueKey(selectedMonth), selectedMonth: selectedMonth),
          ],
        ),
      ),
    );
  }

  Widget buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        infoItem("शाळेचे नाव", schoolName),
        infoItem("केंद्र शाळा", group),
        infoItem("तालुका", taluka),
        infoItem("जिल्हा", district),
        const Divider(),
        infoItem("पटसंख्या", totalStudents),
        infoItem("उपस्थित विद्यार्थी", takingMeal),
        infoItem("तांदूळ प्राप्त दिनांक", riceDate, isDate: true, onTap: () => selectDate(true)),
        TextField(
          controller: riceReceiptController,
          decoration: const InputDecoration(
            labelText: "तांदूळ पावती क्रमांक",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        infoItem("धान्य प्राप्त दिनांक", grainsDate, isDate: true, onTap: () => selectDate(false)),
        TextField(
          controller: grainsReceiptController,
          decoration: const InputDecoration(
            labelText: "धान्य पावती क्रमांक",
            border: OutlineInputBorder(),
          ),
        ),
        const Divider(height: 30),
        infoItem("एकूण कार्यदिवस", workingDays),
        infoItem("अन्न शिजवलेले दिवस", cookDays),
      ],
    );
  }

  Widget buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [
          infoItem("शाळेचे नाव", schoolName),
          infoItem("केंद्र शाळा", group),
          infoItem("तालुका", taluka),
          infoItem("जिल्हा", district),
        ])),
        Expanded(child: Column(children: [
          infoItem("पटसंख्या", totalStudents),
          infoItem("उपस्थित विद्यार्थी", takingMeal),
          infoItem("तांदूळ प्राप्त दिनांक", riceDate, isDate: true, onTap: () => selectDate(true)),
          TextField(
            controller: riceReceiptController,
            decoration: const InputDecoration(
              labelText: "तांदूळ पावती क्रमांक",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          infoItem("धान्य प्राप्त दिनांक", grainsDate, isDate: true, onTap: () => selectDate(false)),
          TextField(
            controller: grainsReceiptController,
            decoration: const InputDecoration(
              labelText: "धान्य पावती क्रमांक",
              border: OutlineInputBorder(),
            ),
          ),
        ])),
        Expanded(child: Column(children: [
          infoItem("एकूण कार्यदिवस", workingDays),
          infoItem("अन्न शिजवलेले दिवस", cookDays),
        ])),
      ],
    );
  }
}
