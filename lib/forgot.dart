import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart';
// import 'theme.dart'; // Import your theme file
// import 'colors.dart'; // Import your colors file

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController email = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  reset() async {
    if (email.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email address';
        successMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );
      
      setState(() {
        successMessage = 'Password reset link sent to your email';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to send reset email. Please check your email address.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppTheme.spacingXXL),
              
              // Header Icon
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Title
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.spacingM),
              
              // Subtitle
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.spacingXXL),
              
              // Email Input Card
              Card(
                elevation: AppTheme.elevationS,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      SizedBox(height: AppTheme.spacingM),
                      
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: TextStyle(color: AppColors.textLight),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            borderSide: BorderSide(color: AppColors.error),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingL),
              
              // Error Message
              if (errorMessage != null)
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Success Message
              if (successMessage != null)
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.inStock.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppColors.inStock.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.inStock,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inStock,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Send Reset Link Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: AppTheme.elevationS,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingM),
                            Text(
                              'Sending...',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Send Reset Link',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingL),
              
              // Back to Login
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                ),
                child: Text(
                  'Back to Login',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }
}