import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supplify/screens/splash_screen.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SupplifyApp());
}

class SupplifyApp extends StatelessWidget {
  const SupplifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Supplify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
       debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
