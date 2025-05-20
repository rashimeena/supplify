import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

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
  final String settingsDocId = 'app_config'; // customize this ID if needed

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
  try {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    
    final doc = await settingsRef.doc(settingsDocId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _thresholdController.text = data['lowStockThreshold']?.toString() ?? '5';
      _showAlerts = data['showAlerts'] ?? false;
    } else {
      // Create default settings document if it doesn't exist
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
    // Check if user is authenticated
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
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Low Stock Threshold',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter threshold value',
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Show Low Stock Alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Alerts'),
                    value: _showAlerts,
                    onChanged: (val) {
                      setState(() => _showAlerts = val);
                    },
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetDefaults,
                          child: const Text('Reset to Defaults'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
