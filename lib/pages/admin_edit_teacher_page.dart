// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, curly_braces_in_flow_control_structures, prefer_const_constructors

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AdminEditTeacherPage extends StatefulWidget {
  final String teacherId;

  const AdminEditTeacherPage({super.key, required this.teacherId});

  @override
  _AdminEditTeacherPageState createState() => _AdminEditTeacherPageState();
}

class _AdminEditTeacherPageState extends State<AdminEditTeacherPage> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addharNoController = TextEditingController();

  bool _isImageUploading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;
  String selectedClass = '';
  List<String> classNames = [];

  String _selectedAdminType = '';
  final List<String> adminTypes = [
    'teacher',
    'headofteacher',
    'receptionIncharge'
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  void _loadTeacherData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.teacherId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _fullNameController.text = snapshot['fullName'] ?? '';
          _userNameController.text = snapshot['userName'] ?? '';
          _emailController.text = snapshot['email'] ?? '';
          _passwordController.text = snapshot['password'] ?? '';
          _selectedAdminType = snapshot['adminType'] ?? '';
          _addharNoController.text = snapshot['addharNo'] ?? '';
          _imageUrl = snapshot['imageUrl'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher not found!')),
        );
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load teacher data')),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isImageUploading = true;
      });
      final compressedImage = await compressImage(File(pickedFile.path));
      setState(() {
        _selectedImage = compressedImage;
      });
      final newImageUrl = await uploadImage(_selectedImage!);
      if (newImageUrl != null) {
        _imageUrl = newImageUrl;

        // ✅ Firestore मध्ये लगेच image URL update कर
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(widget.teacherId)
            .update({'imageUrl': _imageUrl});
      }

      setState(() {
        _isImageUploading = false;
      });
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
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      return null;
    }
  }

  void _updateTeacher() async {
    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'userName': _userNameController.text.trim(),
        'email': _emailController.text.trim(),
        'adminType': _selectedAdminType,
        'addharNo': _addharNoController.text.trim(),
        'imageUrl': _imageUrl ?? '',
      };

      if (_passwordController.text.isNotEmpty) {
        updatedData['password'] = _passwordController.text;
      }

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.teacherId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update teacher: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Update Teacher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 400
                ? 400
                : MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userNameController,
                  decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'User Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addharNoController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    labelText: 'Addhar No',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter Addhar No';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    labelText: 'Password (optional)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAdminType.isEmpty ? null : _selectedAdminType,
                  items: adminTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Admin Type'),
                  onChanged: (value) {
                    setState(() {
                      _selectedAdminType = value!;
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
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                                      ? NetworkImage(_imageUrl!)
                                          as ImageProvider
                                      : null),
                              child: _selectedImage == null &&
                                      (_imageUrl == null || _imageUrl!.isEmpty)
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
                      const Text("Tap to change photo"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 130,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateTeacher,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      backgroundColor:
                          WidgetStateProperty.all(Colors.transparent),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Update',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
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
    );
  }
}
