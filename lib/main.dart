
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDNbfGGHh-xQK_U3tzYvjElTJ8uLw1atjE",
        authDomain: "myapp-6bd7a.firebaseapp.com",
        projectId: "myapp-6bd7a",
        storageBucket: "myapp-6bd7a.appspot.com",
        messagingSenderId: "231755162966",
        appId: "1:231755162966:web:2e83a75b41a9edefdf62f7",
        measurementId: "G-DCF2ZS3MM0",
      ),
    );
  } catch (e) {
    print('Firebase already initialized or error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});   

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Flutter Firebase Auth',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: LoginPage(),
    );
  }
}
