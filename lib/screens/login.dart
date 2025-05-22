// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:supplify/forgot.dart';
// import 'package:supplify/signup.dart';

// class Login extends StatefulWidget {
//   const Login({super.key});

//   @override
//   State<Login> createState() => _LoginState();
// }

// class _LoginState extends State<Login> {

//   TextEditingController email = TextEditingController();
//   TextEditingController password = TextEditingController();

//   signIn()async{
//     await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email.text,
//       password: password.text
//     );
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//        appBar: AppBar(title: Text("Login"),),
//        body:Padding(
//          padding: const EdgeInsets.all(20.0),
//          child: Column(
//           children: [
//             TextField(
//               controller: email,
//               decoration: InputDecoration(hintText: 'enter email'),
               
//          ),
//             TextField(
//               controller: password,
//               decoration: InputDecoration(hintText: 'enter password'),
               
//          ),
//          ElevatedButton(onPressed: (()=>signIn()), child: Text("Login")),
//          SizedBox(height: 30,),
//           // Make sure to import or define the Signup widget above this usage.
//           ElevatedButton(onPressed: (()=>Get.to(Signup())), child: Text("Register Now")),
//           SizedBox(height: 30,),
//            ElevatedButton(onPressed: (()=>Get.to(Forgot())), child: Text("Fogot Password?"))
//          ],
//          ),
//        )

//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supplify/forgot.dart';
import 'package:supplify/signup.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart';
// import 'theme.dart'; // Import your theme file
// import 'colors.dart'; // Import your colors file

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  signIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );
    } catch (e) {
      // Handle error (you can add a snackbar or dialog here)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Welcome Back"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              SizedBox(height: AppTheme.spacingXL),
              
              // App Logo/Icon (you can replace with your logo)
              Container(
                height: 80,
                width: 80,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 40,
                  color: AppColors.textOnPrimary,
                ),
              ),
              
              // Welcome Text
              Text(
                'Sign In',
                style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.spacingS),
              
              Text(
                'Enter your credentials to access your account',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.spacingXXL),
              
              // Login Form Card
              Card(
                elevation: AppTheme.elevationM,
                color: AppColors.cardBackground,
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      Text(
                        'Email Address',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Password Field
                      Text(
                        'Password',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: password,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: const TextStyle(color: AppColors.textLight),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Get.to(() => Forgot()),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Login Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            elevation: AppTheme.elevationS,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textOnPrimary,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                    child: Text(
                      'OR',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Register Button
              OutlinedButton.icon(
                onPressed: () => Get.to(() => Signup()),
                icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
                label: const Text('Create New Account', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXXL),
              
              // Footer
              Text(
                'By signing in, you agree to our Terms of Service and Privacy Policy',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
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