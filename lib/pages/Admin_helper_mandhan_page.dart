import 'package:flutter/material.dart';
import 'package:zp/pages/Admin_helper_mandhantable_page.dart'; // Adjust import as per your file structure

class HelperMandanPage extends StatelessWidget {
  final String helperName;

  const HelperMandanPage({super.key, required this.helperName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              tileMode: TileMode.mirror,
            ),
          ),
          child: AppBar(
            title: Text(
              '$helperName - मानधन अहवाल',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HelperMandanTable(helperName: helperName),
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    HelperMandanTable.showAddEntryDialog(context, helperName);
  },
  backgroundColor: Colors.purple,
  child: const Icon(
    Icons.add,
    color: Colors.white, // 👉 प्लस आयकॉन पांढरा केला
  ),
),

    );
  }
}
