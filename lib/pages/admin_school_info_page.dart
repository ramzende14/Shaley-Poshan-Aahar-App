
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CombinedInfoBoxPage extends StatefulWidget {
//   const CombinedInfoBoxPage({super.key});

//   @override
//   State<CombinedInfoBoxPage> createState() => _CombinedInfoBoxPageState();
// }

// class _CombinedInfoBoxPageState extends State<CombinedInfoBoxPage> {
//   String schoolName = "Z.P. Primary School";
//   String group = "Karjat Center";
//   String taluka = "Karjat";
//   String district = "Ahmednagar";
//   String totalStudents = "-";
//   String takingMeal = "112";
//   String notTakingMeal = "8";
//   String riceDate = "01/07/2025";
//   String grainsDate = "03/07/2025";
//   String workingDays = "20";
//   String cookDays = "18";
//   String headSign = "प्रमुख सही";
//   String committeeSign = "समिती सही";

//   @override
//   void initState() {
//     super.initState();
//     fetchTotalStudents();
//   }

//   Future<void> fetchTotalStudents() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection("schools")
//         .doc("zp_school_01")
//         .get();

//     if (snapshot.exists) {
//       final data = snapshot.data();
//       setState(() {
//         totalStudents = data?['total_students'].toString() ?? "-";
//       });
//     }
//   }

//   Widget infoItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "$label: ",
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildMobileLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         infoItem("शाळेचे नाव", schoolName),
//         infoItem("केंद्र शाळा", group),
//         infoItem("तालुका", taluka),
//         infoItem("जिल्हा", district),
//         const Divider(),
//         infoItem("पटसंख्या", totalStudents),
//         infoItem("उपस्थित विद्यार्थी", takingMeal),
//         infoItem("तांदूळ प्राप्त दिनांक", riceDate),
//         infoItem("धान्य प्राप्त दिनांक", grainsDate),
//         const Divider(),
//         infoItem("एकूण कार्यदिवस", workingDays),
//         infoItem("अन्न शिजवलेले दिवस", cookDays),
        
//       ],
//     );
//   }

//   Widget buildTabletLayout() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               infoItem("शाळेचे नाव", schoolName),
//               infoItem("केंद्र शाळा", group),
//               infoItem("तालुका", taluka),
//               infoItem("जिल्हा", district),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               infoItem("पटसंख्या", totalStudents),
//               infoItem("उपस्थित विद्यार्थी", takingMeal),
//               infoItem("तांदूळ प्राप्त दिनांक", riceDate),
//               infoItem("धान्य प्राप्त दिनांक", grainsDate),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               infoItem("एकूण कार्यदिवस", workingDays),
//               infoItem("अन्न शिजवलेले दिवस", cookDays),
             
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
     
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(12),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.black),
//           ),
//           child: isMobile ? buildMobileLayout() : buildTabletLayout(),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String takingMeal = "-";
  String riceDate = "-";
  String grainsDate = "-";
  String workingDays = "-";
  String cookDays = "-";

  String selectedMonth = "July";
  List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<Map<String, dynamic>> vastuList = [];

  @override
  void initState() {
    super.initState();
    fetchBasicInfo();
    fetchVastuDetails();
  }

  Future<void> fetchBasicInfo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("schools")
        .doc("zp_school_01")
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        totalStudents = data?['total_students'].toString() ?? "-";
        takingMeal = data?['taking_meal'].toString() ?? "-";
        riceDate = data?['rice_date'] ?? "-";
        grainsDate = data?['grains_date'] ?? "-";
        workingDays = data?['working_days'].toString() ?? "-";
        cookDays = data?['cook_days'].toString() ?? "-";
      });
    }
  }

  Future<void> fetchVastuDetails() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc('zp_school_01')
        .collection('vastu')
        .doc(selectedMonth.toLowerCase())
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        vastuList = List<Map<String, dynamic>>.from(data?['items'] ?? []);
      });
    } else {
      setState(() {
        vastuList = [];
      });
    }
  }

  Widget infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  Widget buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? double.infinity
                : MediaQuery.of(context).size.width / 3 - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoItem("शाळेचे नाव", schoolName),
                infoItem("केंद्र शाळा", group),
                infoItem("तालुका", taluka),
                infoItem("जिल्हा", district),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? double.infinity
                : MediaQuery.of(context).size.width / 3 - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoItem("पटसंख्या", totalStudents),
                infoItem("उपस्थित विद्यार्थी", takingMeal),
                infoItem("तांदूळ प्राप्त दिनांक", riceDate),
                infoItem("धान्य प्राप्त दिनांक", grainsDate),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? double.infinity
                : MediaQuery.of(context).size.width / 3 - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoItem("एकूण कार्यदिवस", workingDays),
                infoItem("अन्न शिजवलेले दिवस", cookDays),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVastuTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "महिना निवडा:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: selectedMonth,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMonth = value;
                  });
                  fetchVastuDetails();
                }
              },
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.grey),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("वस्तूचे नाव", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("प्राप्त मात्रा", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("एकक", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...vastuList.map((item) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(item['name'] ?? '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(item['quantity']?.toString() ?? '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(item['unit'] ?? '-'),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("शाळेची माहिती व वस्तू तपशील")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoBox(),
            const SizedBox(height: 20),
            buildVastuTable(),
          ],
        ),
      ),
    );
  }
}
