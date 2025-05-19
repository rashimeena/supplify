import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supplify/screens/main_screen.dart'; // NEW: main screen with bottom nav
import 'package:supplify/screens/login.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Optional: loading
          } else if (snapshot.hasData) {
            return const MainScreen(); // ✅ This shows the Bottom Navigation
          } else {
            return const Login();
          }
        },
      ),
    );
  }
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:supplify/screens/homescreen.dart';
// import 'package:supplify/screens/login.dart';

// class Wrapper extends StatefulWidget {
//   const Wrapper({super.key});

//   @override
//   State<Wrapper> createState() => _WrapperState();
// }

// class _WrapperState extends State<Wrapper> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             return Homescreen();
//           } else {
//             return Login();
//           }
//         },
//       ),
//     );
//   }
// }
