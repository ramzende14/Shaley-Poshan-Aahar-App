// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, prefer_final_fields, unused_field, avoid_print, await_only_futures, sort_child_properties_last, prefer_const_constructors, unused_import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zp/pages/admin_add_vastu_page.dart';
import 'package:zp/pages/Admin_helper_card_list.dart';
import 'package:zp/pages/Admin_helper_mandhantable_page.dart';
import 'package:zp/pages/Admin_kendrapramukh_ahwal.dart';
import 'package:zp/pages/admin_sahity_yadi.dart';
import 'package:zp/pages/admin_school_info_page.dart' hide CombinedInfoBoxPage;
import 'package:zp/pages/MotnhWiseWrapperPage.dart';
import 'package:zp/pages/admin_AddDaily_record_page.dart';
import 'package:zp/pages/admin_add_class_page.dart';
import 'package:zp/pages/admin_add_student_page.dart';
import 'package:zp/pages/admin_add_tandulentery_page.dart';
import 'package:zp/pages/admin_add_teacher_page.dart';
import 'package:zp/pages/admin_app_drawer.dart';
import 'package:zp/pages/admin_daily_records_page.dart';
import 'package:zp/pages/admin_list_attendance_student_page.dart';
import 'package:zp/pages/admin_list_class_page.dart';
import 'package:zp/pages/admin_list_student_page.dart';
import 'package:zp/pages/admin_list_tandul_hishob_page.dart';
import 'package:zp/pages/admin_list_teacher_page.dart';
import 'package:zp/pages/admin_vastunche_record_page.dart';
import 'package:zp/pages/login_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  List<int> _navigationStack = [0];

  final List<Widget> _pages = [
    TandulHishobPage(),
     MonthWiseWrapperPage(
       builder: (month) => VastuncheRecord(selectedMonth: month),
     ),
     DailyRecordTable(),
    //const Center(child: Text("रोजचा खर्च", style: TextStyle(fontSize: 20))),
    //const Center(child: Text("साहित्य", style: TextStyle(fontSize: 20))),
    PoshanTablePage(),
    //const Center(child: Text("मदतनीस मानधन अहवाल", style: TextStyle(fontSize: 20))),
    HelperCardList(),
    CombinedInfoBoxPage(),
   // const Center(child: Text("केंद्रप्रमुख अहवाल", style: TextStyle(fontSize: 20))),
    AdminListClassPage(),
    //AdminAddClassPage(),
    AdminListAttendanceStudentPage(studentEmail: '', studentId: '',),
    AdminListStudentPage(adminType: '',),
    AdminListTeacherPage(adminType: '',),

  ];

  final List<String> _titles = [
    "तांदुळाचा हिशोब",
    "वस्तूची यादी",
    "रोजचा खर्च",
    "साहित्य",
    "मदतनीस मानधन अहवाल",
    "केंद्रप्रमुख अहवाल",
    "वर्गाची यादी",
   // "वर्ग जोडा",
    "हजेरी",
    "विद्यार्थी",
    "शिक्षक",
  ];

  final List<Color> repeatedColors = [Colors.blue, Colors.purple];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navigationStack.length > 1) {
          setState(() {
            _navigationStack.removeLast();
            _selectedIndex = _navigationStack.last;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: repeatedColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: _getAppBarActions(),
            ),
          ),
        ),
        drawer: LayoutBuilder(
          builder: (context, constraints) {
            double drawerWidth = constraints.maxWidth < 600
                ? MediaQuery.of(context).size.width * 0.50
                : MediaQuery.of(context).size.width * 0.15;

            return SizedBox(
              width: drawerWidth,
              child: AppDrawer(
                onSelectPage: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _navigationStack.add(index);
                  });
                },
              ),
            );
          },
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            currentIndex: (_selectedIndex > 5) ? 0 : _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                _navigationStack.add(index);
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.rice_bowl), label: 'तांदुळाचा हिशोब'),
              BottomNavigationBarItem(icon: Icon(Icons.label), label: 'वस्तूचा हिशोब'),
              BottomNavigationBarItem(icon: Icon(Icons.money), label: 'रोजचा खर्च'),
              BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'साहित्य यादी'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'मदतनीस मानधन'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'केंद्रप्रमुख अहवाल'),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getAppBarActions() {
  // For Students
  if (_titles[_selectedIndex] == 'विद्यार्थी') {
    return [
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminAddStudentPage()),
          );
        },
      ),
    ];
  }
  // For Teachers
  else if (_titles[_selectedIndex] == 'शिक्षक') {
    return [
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminAddTeacherPage()),
          );
        },
      ),
    ];
  }
  else if (_titles[_selectedIndex] == 'वर्गाची यादी') {
    return [
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminAddClassPage()),
          );
        },
      ),
    ];
  }
  else if (_titles[_selectedIndex] == 'तांदुळाचा हिशोब') {
    return [
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTandulEntryCard()),
          );
        },
      ),
    ];
  }
//  else if (_titles[_selectedIndex] == 'वस्तूचे नाव') {
//   return [
//     IconButton(
//       icon: const Icon(Icons.add, color: Colors.white),
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (_) => MonthWiseWrapperPage(
//             builder: (selectedMonth) => AddVastuEntryDialog(selectedMonth: selectedMonth),
//           ),
//         );
//       },
//     ),
//   ];
// }

 
   else if (_titles[_selectedIndex] == 'रोजचा खर्च') {
    return [
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDailyRecordPage()),
          );
        },
      ),
    ];
  }
  // Default: No actions
  //  else if (_titles[_selectedIndex] == '') {
  //   return [
  //     IconButton(
  //       icon: const Icon(Icons.add, color: Colors.white),
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => AddTandulEntryCard()),
  //         );
  //       },
  //     ),
  //   ];
  // }
  // Default: No actions
  //  else if (_titles[_selectedIndex] == '') {
  //   return [
  //     IconButton(
  //       icon: const Icon(Icons.add, color: Colors.white),
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => AddTandulEntryCard()),
  //         );
  //       },
  //     ),
  //   ];
  // }
  // Default: No actions
  else {
    return [];
  }
}

}


Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', false);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
  );
}
