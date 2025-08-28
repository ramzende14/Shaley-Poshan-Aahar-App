// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AdminAddTeacherPage extends StatefulWidget {
  const AdminAddTeacherPage({super.key});

  @override
  _AdminAddTeacherPageState createState() => _AdminAddTeacherPageState();
}

class _AdminAddTeacherPageState extends State<AdminAddTeacherPage> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String selectedAdminType = '';
  List<String> adminTypes = ['teacher', 'headofteacher', 'receptionIncharge'];
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addharNoController = TextEditingController();
  final _phoneNoController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  bool _isImageUploading = false;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> checkUsernameExists(String username) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('admins')
        .where('userName', isEqualTo: username)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  void addteacher() async {
    if (!_formKey.currentState!.validate()) return;

    final String fullName = _fullNameController.text.trim();
    final String userName = _userNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String addharNo = _addharNoController.text.trim();
    final String phoneNo = _phoneNoController.text.trim();

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
      await FirebaseFirestore.instance.collection('admins').add({
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'adminType': selectedAdminType,
        'imageUrl': _imageUrl ?? '',
        'addharNo': addharNo,
        'phoneNo': phoneNo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding Teacher: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
            'teacher_images/$fileName',
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
          'Add Teacher',
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
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Username
                      TextFormField(
                        controller: _userNameController,
                        decoration:
                            const InputDecoration(labelText: 'User Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter username'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _addharNoController,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'Addhar Number',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'addhar Number'
                            : null,
                      ),

                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneNoController,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          labelText: 'phone Number',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'phone Number'
                            : null,
                      ),

                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
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
                      const SizedBox(height: 20),

// Admin Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedAdminType.isEmpty
                            ? null
                            : selectedAdminType,
                        items: adminTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Admin Type'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Select admin type'
                            : null,
                        onChanged: (value) {
                          setState(() {
                            selectedAdminType = value!;
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
                              onPressed: _isLoading ? null : addteacher,
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
