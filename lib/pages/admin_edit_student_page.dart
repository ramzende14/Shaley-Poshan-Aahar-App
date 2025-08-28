  // ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, curly_braces_in_flow_control_structures, prefer_const_constructors
  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_image_compress/flutter_image_compress.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:path/path.dart' as path;

  class AdminEditStudentPage extends StatefulWidget {
    final String studentId;

    const AdminEditStudentPage({super.key, required this.studentId});

    @override
    _AdminEditStudentPageState createState() => _AdminEditStudentPageState();
  }

  class _AdminEditStudentPageState extends State<AdminEditStudentPage> {
    bool _isLoading = false;
    bool _isPasswordVisible = false;

    final _fullNameController = TextEditingController();
    final _userNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _addharNoController = TextEditingController();
    final _studentphoneNumberController = TextEditingController();
    final _parentsphoneNumberController = TextEditingController();

    bool _isImageUploading = false;
    File? _selectedImage;
    final ImagePicker _picker = ImagePicker();
    String? _imageUrl;
    String selectedClass = '';
    List<String> classNames = [];

    Future<void> fetchClassNames() async {
      try {
        final querySnapshot =
            await FirebaseFirestore.instance.collection('class').get();
        setState(() {
          classNames =
              querySnapshot.docs.map((doc) => doc['name'] as String).toList();
        });
      } catch (e) {
        print('Error fetching class names: $e');
      }
    }

    Future<bool> checkUsernameExists(String username) async {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('userName', isEqualTo: username)
          .where(FieldPath.documentId, isNotEqualTo: widget.studentId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    }

    @override
    void initState() {
      super.initState();
      fetchClassNames();
      _loadStudentData();
    }

    void _loadStudentData() async {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .get();

        if (snapshot.exists) {
          setState(() {
            _fullNameController.text = snapshot['fullName'] ?? '';
            _userNameController.text = snapshot['userName'] ?? '';
            _emailController.text = snapshot['email'] ?? '';
            _addharNoController.text = snapshot['addharNo'] ?? '';
            _studentphoneNumberController.text =
                snapshot['studentphoneNumber'] ?? '';
            _parentsphoneNumberController.text =
                snapshot['parentsphoneNumber'] ?? '';
            _passwordController.text = snapshot['password'] ?? '';
            _imageUrl = snapshot['imageUrl'] ?? '';
            setState(() {});
            selectedClass = snapshot['class'] ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student not found!')),
          );
        }
      } catch (e) {
        print('Error loading student data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load student data')),
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
              .collection('students')
              .doc(widget.studentId)
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
              'student_images/$fileName',
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

    void _updateStudent() async {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedData = {
          'fullName': _fullNameController.text,
          'userName': _userNameController.text,
          'addharNo': _addharNoController.text.trim(),
          'studentphoneNumber': _studentphoneNumberController.text.trim(),
          'parentsphoneNumber': _parentsphoneNumberController.text.trim(),
          'email': _emailController.text,
          'class': selectedClass,
          'imageUrl': _imageUrl ?? '',
        };

        if (_passwordController.text.isNotEmpty) {
          updatedData['password'] = _passwordController.text;
        }

        bool exists = await checkUsernameExists(_userNameController.text.trim());

        if (exists) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('This name is already taken, please choose another name.'),
            ),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update student: $e')),
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
            'Update Student',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        labelText: 'Name'),
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
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Aadhaar Number',
                      counterText: '', // Removes maxLength counter text
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter Aadhaar Number';
                      } else if (value.length != 12) {
                        return 'Aadhaar must be 12 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _studentphoneNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Student Phone Number',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter student\'s phone number';
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parentsphoneNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'Parent\'s Phone Number',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter parent\'s phone number';
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter valid 10-digit phone number';
                      }
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
                  classNames.isEmpty
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: selectedClass.isEmpty ? null : selectedClass,
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
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.transparent,
                            ),
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                          onPressed: _isLoading ? null : _updateStudent,
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
      );
    }

    // ignore: unused_element
    InputDecoration _inputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.black,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
      );
    }
  }
