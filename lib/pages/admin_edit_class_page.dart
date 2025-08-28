// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_apiimport 'package:cloud_firestore/cloud_firestore.dart';, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api, library_private_types_in_public_api
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEditClassPage extends StatefulWidget {
  final String classId;

  const AdminEditClassPage({super.key, required this.classId});

  @override
  // ignore: library_private_types_in_public_api
  _AdminEditClassPageState createState() => _AdminEditClassPageState();
}

class _AdminEditClassPageState extends State<AdminEditClassPage> {
  final _classController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  bool _isLoading = false; // Flag to show loading state

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  // Fetch the class data from Firestore
  void _loadClassData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('class')
        .doc(widget.classId)
        .get();

    if (snapshot.exists) {
      setState(() {
        _classController.text = snapshot['name'] ?? '';
      });
    }
  }

  // Update the class data
  void _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('class')
          .doc(widget.classId)
          .update({'name': _classController.text});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update class: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Important for keyboard adjustments
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Update Class',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                width: MediaQuery.of(context).size.width < 400
                    ? MediaQuery.of(context).size.width * 0.85
                    : 350, // Responsive width
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Make form compact
                    children: [
                      TextFormField(
                        controller: _classController,
                        decoration: InputDecoration(
                          labelText: 'Class Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the class name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: 130,
                            height: 70,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                foregroundColor: Colors.white,
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                  (states) => Colors.transparent,
                                ),
                                shadowColor:
                                    WidgetStateProperty.all(Colors.transparent),
                              ),
                              onPressed: _isLoading ? null : _updateClass,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Update',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


