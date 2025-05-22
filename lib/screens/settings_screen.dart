import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart';

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
        );
      }
    } catch (e) {
      print('Low stock check error: $e');
      Get.snackbar('Error', 'Could not check low stock items.');
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
      Get.snackbar('Error', 'Failed to load settings: ${e.toString()}');
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
        Get.snackbar('Invalid Input', 'Please enter a valid positive number.');
        setState(() => _loading = false);
        return;
      }
      await settingsRef.doc(settingsDocId).set({
        'lowStockThreshold': threshold,
        'showAlerts': _showAlerts,
      });
      Get.snackbar('Success', 'Settings saved successfully');
    } catch (e) {
      print('Settings save error: $e');
      Get.snackbar('Error', 'Failed to save settings: ${e.toString()}');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 25), // 0.1 * 255 = 25
                          AppColors.primary.withValues(alpha: 13), // 0.05 * 255 = 13
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 51), // 0.2 * 255 = 51
                        width: 1,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: AppColors.textOnPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory Settings',
                                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                'Configure your inventory preferences',
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),

                  // Low Stock Threshold Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: AppColors.lowStockBackground,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.lowStock,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Text(
                                'Low Stock Threshold',
                                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Set the minimum quantity to trigger low stock warnings',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextField(
                            controller: _thresholdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Threshold Value',
                              hintText: 'Enter minimum quantity',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Alerts Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 25), // 0.1 * 255 = 25
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Text(
                                'Notification Settings',
                                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Manage how you receive low stock notifications',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusL),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 76), // 0.3 * 255 = 76
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                                vertical: AppTheme.spacingS,
                              ),
                              title: Text(
                                'Enable Low Stock Alerts',
                                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                _showAlerts 
                                    ? 'You will receive notifications when items are low'
                                    : 'No notifications will be sent',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              value: _showAlerts,
                              onChanged: (val) {
                                setState(() => _showAlerts = val);
                              },
                              secondary: Container(
                                padding: const EdgeInsets.all(AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: _showAlerts 
                                      ? AppColors.primary.withValues(alpha: 25) // 0.1 * 255 = 25
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: Icon(
                                  _showAlerts 
                                      ? Icons.notifications_active
                                      : Icons.notifications_off_outlined,
                                  color: _showAlerts 
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetDefaults,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reset to Defaults'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Quick Actions Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.flash_on_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Quick Actions',
                                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: checkLowStockAndNotify,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Check Low Stock Items Now'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                                backgroundColor: AppColors.primary.withValues(alpha: 13), // 0.05 * 255 = 13
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingM),
                ],
              ),
            ),
    );
  }
}