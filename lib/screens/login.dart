import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supplify/forgot.dart';
import 'package:supplify/signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  signIn()async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.text,
      password: password.text
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: Text("Login"),),
       body:Padding(
         padding: const EdgeInsets.all(20.0),
         child: Column(
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: 'enter email'),
               
         ),
            TextField(
              controller: password,
              decoration: InputDecoration(hintText: 'enter password'),
               
         ),
         ElevatedButton(onPressed: (()=>signIn()), child: Text("Login")),
         SizedBox(height: 30,),
          // Make sure to import or define the Signup widget above this usage.
          ElevatedButton(onPressed: (()=>Get.to(Signup())), child: Text("Register Now")),
          SizedBox(height: 30,),
           ElevatedButton(onPressed: (()=>Get.to(Forgot())), child: Text("Fogot Password?"))
         ],
         ),
       )

    );
  }
}






























// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder(
      
//     );
//   }
// } }
// }