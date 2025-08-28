// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print, prefer_const_constructors

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AdminAddStudentPage extends StatefulWidget {
  const AdminAddStudentPage({super.key});

  @override
  _AdminAddStudentPageState createState() => _AdminAddStudentPageState();
}

class _AdminAddStudentPageState extends State<AdminAddStudentPage> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String selectedClass = "";
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addharNoController = TextEditingController();
  final _studentphoneNumberController = TextEditingController();
  final _parentsphoneNumberController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  bool _isImageUploading = false;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  List<String> classNames = [];

  @override
  void initState() {
    super.initState();
    fetchClassNames();
  }

  Future<void> fetchClassNames() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('class').get();
    setState(() {
      classNames =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<bool> checkUsernameExists(String username) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('students')
        .where('userName', isEqualTo: username)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _isImageUploading = true;
        });

        final compressedImage = await compressImage(File(pickedFile.path));

        setState(() {
          _selectedImage = compressedImage;
        });

        _imageUrl = await uploadImage(_selectedImage!);

        setState(() {
          _isImageUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageUploading = false;
      });
      print("Failed to pick or compress image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image error: $e")),
      );
    }
  }

  Future<File> compressImage(File file) async {
    try {
      final targetPath =
          "${file.parent.path}/temp_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 20,
      );

      if (compressedXFile == null) {
        throw Exception("Image compression returned null");
      }

      final compressedFile = File(compressedXFile.path);
      return compressedFile;
    } catch (e) {
      print("Compression error: $e");
      rethrow; // send error back to pickImage() catch block
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final ref = FirebaseStorage.instance.ref().child(
            'student_images/$fileName',
          );
      final uploadTask = ref.putFile(imageFile);
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      print("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      return null;
    }
  }

  void addStudentData() async {
    if (!_formKey.currentState!.validate()) return;

    final String fullName = _fullNameController.text.trim();
    final String userName = _userNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String addharNo = _addharNoController.text.trim();
    final String studentphoneNumber = _studentphoneNumberController.text.trim();
    final String parentsphoneNumber = _parentsphoneNumberController.text.trim();

    bool exists = await checkUsernameExists(userName);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This username is already taken.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('students').add({
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'class': selectedClass,
        'imageUrl': _imageUrl ?? '',
        'addharNo': addharNo,
        'studentphoneNumber': studentphoneNumber,
        'parentsphoneNumber': parentsphoneNumber,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding student: $e')));
    } finally {
      setState(() => _isLoading = false);
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
          'Add Student',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8, // Shadow effect
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 250, // Make form compact
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            labelText: 'Full Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter full name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Username
                      TextFormField(
                        controller: _userNameController,
                        decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            labelText: 'User Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter username'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          if (!value.endsWith('@gmail.com')) {
                            return 'Only Gmail accounts are allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _addharNoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'Aadhaar Number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Aadhaar number';
                          } else if (value.length != 12) {
                            return 'Aadhaar number must be 12 digits';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _studentphoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'Phone Number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          } else if (value.length != 10 ||
                              !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Enter valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _parentsphoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'Parents Phone Number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter parent\'s phone number';
                          } else if (value.length != 10 ||
                              !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Enter valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Class Dropdown
                      classNames.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value:
                                  selectedClass.isEmpty ? null : selectedClass,
                              items: classNames
                                  .map((className) => DropdownMenuItem(
                                        value: className,
                                        child: Text(className),
                                      ))
                                  .toList(),
                              decoration: const InputDecoration(
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Class'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Select a class'
                                      : null,
                              onChanged: (value) {
                                setState(() {
                                  selectedClass = value!;
                                });
                              },
                            ),

                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            InkWell(
                              onTap: pickImage,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _selectedImage != null
                                        ? FileImage(_selectedImage!)
                                        : null,
                                    child: _selectedImage == null
                                        ? const Icon(
                                            Icons.camera_alt,
                                            size: 40,
                                          )
                                        : null,
                                  ),
                                  if (_isImageUploading)
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text("Tap to upload photo"),
                          ],
                        ),
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
                              onPressed: _isLoading ? null : addStudentData,
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
                                          'Add',
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
