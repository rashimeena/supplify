
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {

  final user = FirebaseAuth.instance.currentUser;

  signout()async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Homescreen"),),
      body: Center(
        child: Text('${user!.email}'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: (()=>signout()), 
        child: Icon(Icons.login_rounded),
      ),

    );
  }
}