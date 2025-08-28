// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onSelectPage;

  const AppDrawer({
    super.key,
    required this.onSelectPage,
  });

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _menuItems = [
      {'title': 'तांदुळचा हिशोब', 'index': 0, 'icon': Icons.rice_bowl},
      {'title': 'वस्तूचे नाव', 'index': 1, 'icon': Icons.label},
      {'title': 'रोजचा खर्च', 'index': 2, 'icon': Icons.money},
      {'title': 'साहित्य', 'index': 3, 'icon': Icons.kitchen},
      {'title': 'मदतनीस मानधन अहवाल', 'index': 4, 'icon': Icons.people},
      {'title': 'केंद्रप्रमुख अहवाल', 'index': 5, 'icon': Icons.assignment},
      {'title': 'वर्गाची यादी', 'index': 6, 'icon': Icons.book},
      //{'title': 'वर्ग जोडा', 'index': 7, 'icon': Icons.help},
        {
          'title': 'हजेरी',
          'index': 7,
          'icon': Icons.event_available
        },
        {'title': 'विद्यार्थी', 'index': 8, 'icon': Icons.people},
        {'title': 'शिक्षक', 'index': 9, 'icon': Icons.person},


    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  

  Future<void> _logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Removed image container here

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _menuItems.map((item) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectPage(item['index']);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2 - 32,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                item['icon'],
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['title'],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
