import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
// import 'package:supplify/utils/colors2.dart';
// import 'package:supplify/utils/theme2.dart';
import 'package:supplify/utils/utils2/colors2.dart';
import 'package:supplify/utils/utils2/theme2.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _thresholdController = TextEditingController();
  bool _showAlerts = false;
  bool _loading = true;

  final CollectionReference settingsRef = FirebaseFirestore.instance.collection('settings');
  late String settingsDocId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      settingsDocId = user.uid;
      _loadSettings();
    } else {
      FirebaseAuth.instance.signInAnonymously().then((userCred) {
        settingsDocId = userCred.user!.uid;
        _loadSettings();
      });
    }
  }
 
  // Alert functionality
  Future<void> checkLowStockAndNotify() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }

      final userId = user!.uid;

      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(userId)
          .get();

      final settings = settingsDoc.data();
      if (settings == null) return;

      final threshold = settings['lowStockThreshold'] ?? 5;
      final showAlerts = settings['showAlerts'] ?? false;

      if (!showAlerts) return;

      final lowStockSnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .where('quantity', isLessThanOrEqualTo: threshold)
          .get();

      if (lowStockSnapshot.docs.isNotEmpty) {
        final itemNames = lowStockSnapshot.docs
            .map((doc) => doc['name'] ?? 'Unnamed Item')
            .join(', ');

        Get.snackbar(
          'Low Stock Alert',
          'Items running low: $itemNames',
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.amber,
          colorText: Colors.black,
        );
      }
    } catch (e) {
      print('Low stock check error: $e');
      Get.snackbar(
        'Error', 
        'Could not check low stock items.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _loadSettings() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      
      final doc = await settingsRef.doc(settingsDocId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _thresholdController.text = data['lowStockThreshold']?.toString() ?? '5';
        _showAlerts = data['showAlerts'] ?? false;
      } else {
        await settingsRef.doc(settingsDocId).set({
          'lowStockThreshold': 5,
          'showAlerts': false,
        });
        _thresholdController.text = '5';
        _showAlerts = false;
      }
    } catch (e) {
      print('Settings load error: $e');
      Get.snackbar(
        'Error', 
        'Failed to load settings: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      
      final threshold = int.tryParse(_thresholdController.text);
      if (threshold == null || threshold < 0) {
        Get.snackbar(
          'Invalid Input', 
          'Please enter a valid positive number.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        setState(() => _loading = false);
        return;
      }
      await settingsRef.doc(settingsDocId).set({
        'lowStockThreshold': threshold,
        'showAlerts': _showAlerts,
      });
      Get.snackbar(
        'Success', 
        'Settings saved successfully',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      print('Settings save error: $e');
      Get.snackbar(
        'Error', 
        'Failed to save settings: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
    setState(() => _loading = false);
  }

  void _resetDefaults() {
    setState(() {
      _thresholdController.text = '5';
      _showAlerts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.lightBlue,
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color.fromARGB(255, 2, 57, 71),
          foregroundColor: Colors.white,
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue.withOpacity(0.1),
                            AppColors.blue.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              
                              color: const Color.fromARGB(255, 7, 56, 68),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inventory Settings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 8, 36, 50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configure your inventory preferences',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.darkBlue.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Low Stock Threshold Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.amber,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Low Stock Threshold',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Set the minimum quantity to trigger low stock warnings',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkBlue.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppColors.darkBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Threshold Value',
                                hintText: 'Enter minimum quantity',
                                prefixIcon: Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.blue,
                                ),
                                labelStyle: TextStyle(color: AppColors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.blue.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.blue, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.blue.withOpacity(0.3)),
                                ),
                                filled: true,
                                fillColor: AppColors.lightBlue.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alerts Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_outlined,
                                    color: AppColors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Notification Settings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Manage how you receive low stock notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkBlue.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  'Enable Low Stock Alerts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                                subtitle: Text(
                                  _showAlerts 
                                      ? 'You will receive notifications when items are low'
                                      : 'No notifications will be sent',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.darkBlue.withOpacity(0.7),
                                  ),
                                ),
                                value: _showAlerts,
                                onChanged: (val) {
                                  setState(() => _showAlerts = val);
                                },
                                activeColor: AppColors.blue,
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _showAlerts 
                                        ? AppColors.blue.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _showAlerts 
                                        ? Icons.notifications_active
                                        : Icons.notifications_off_outlined,
                                    color: _showAlerts 
                                        ? AppColors.blue
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetDefaults,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset to Defaults'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.blue, width: 2),
                              foregroundColor: AppColors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flash_on_outlined,
                                  color: AppColors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: checkLowStockAndNotify,
                                icon: const Icon(Icons.search_rounded),
                                label: const Text('Check Low Stock Items Now'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}