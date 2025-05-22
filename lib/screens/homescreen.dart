import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class InventoryItem {
  String id; // Add document ID field
  String name;
  String category;
  int quantity;
  DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.lastUpdated,
  });

  // Convert to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Create an InventoryItem from a Firestore document
  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

class _HomescreenState extends State<Homescreen> {
  // Add low stock threshold variable
  int _lowStockThreshold = 5;

  Future<void> logStockChange({
    required String itemId,
    required String action,
    required String name,
    required String category,
    required int quantityChange,
  }) async {
    await FirebaseFirestore.instance.collection('stock_logs').add({
      'itemId': itemId,
      'action': action, // 'add', 'update', or 'delete'
      'name': name,
      'category': category,
      'quantityChange': quantityChange,
      'timestamp': Timestamp.now(),
      'userId': user?.uid,
    });
  }

  // Method to check if item is low stock
  bool _isLowStock(int quantity) {
    return quantity <= _lowStockThreshold;
  }

  // Method to get stock status color
  Color _getStockStatusColor(int quantity) {
    if (quantity == 0) return Colors.red.shade700;
    if (quantity <= _lowStockThreshold) return Colors.orange.shade700;
    return Colors.green.shade600;
  }

  // Method to get stock status text
  String _getStockStatusText(int quantity) {
    if (quantity == 0) return 'OUT OF STOCK';
    if (quantity <= _lowStockThreshold) return 'LOW STOCK';
    return 'IN STOCK';
  }

  // Method to get stock status icon
  IconData _getStockStatusIcon(int quantity) {
    if (quantity == 0) return Icons.error;
    if (quantity <= _lowStockThreshold) return Icons.warning;
    return Icons.check_circle;
  }

  // Load user settings including low stock threshold
  Future<void> _loadUserSettings() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(currentUser.uid)
          .get();

      if (settingsDoc.exists) {
        final settings = settingsDoc.data();
        setState(() {
          _lowStockThreshold = settings?['lowStockThreshold'] ?? 5;
        });
      }
    } catch (e) {
      print('Error loading user settings: $e');
    }
  }

  // Low stock alert functionality
  Future<void> checkLowStockAndNotify() async {
    try {
      // Ensure user is authenticated
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user authenticated, signing in anonymously...');
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        currentUser = userCredential.user;
      }

      if (currentUser == null) {
        print('Failed to authenticate user');
        return;
      }

      final userId = currentUser.uid;
      print('Checking low stock for user: $userId');

      // Get user-specific settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(userId)
          .get();

      print('Settings doc exists: ${settingsDoc.exists}');

      final settings = settingsDoc.data();
      if (settings == null) {
        print('No settings found for user, using defaults');
        // Use default values if no settings exist
        final threshold = 5;
        final showAlerts = false;
        
        if (!showAlerts) {
          print('Alerts disabled by default');
          return;
        }
      } else {
        final threshold = settings['lowStockThreshold'] ?? 5;
        final showAlerts = settings['showAlerts'] ?? false;
        
        print('Settings - threshold: $threshold, showAlerts: $showAlerts');

        if (!showAlerts) {
          print('Alerts disabled in settings');
          return;
        }

        // Query all inventory items for the user first, then filter in memory
        print('Querying all inventory for user, then filtering for quantity <= $threshold');
        final allUserItemsSnapshot = await FirebaseFirestore.instance
            .collection('inventory')
            .where('userId', isEqualTo: userId)
            .get();
        
        // Filter for low stock items in memory
        final lowStockDocs = allUserItemsSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final quantity = data['quantity'] as int? ?? 0;
          return quantity <= threshold;
        }).toList();

        print('Found ${lowStockDocs.length} low stock items');

        if (lowStockDocs.isNotEmpty && mounted) {
          final itemNames = lowStockDocs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .map((data) => data['name']?.toString() ?? 'Unnamed Item')
              .join(', ');

          print('Low stock items: $itemNames');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Low Stock Alert',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Items running low: $itemNames', style: TextStyle( color: Colors.black12),),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade100,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Low stock check error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Could not check low stock items'),
              ],
            ),
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  // Reference to the Firestore collection
  final CollectionReference _inventoryCollection = 
      FirebaseFirestore.instance.collection('inventory');

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();

  List<InventoryItem> _allItems = [];
  bool _isLoading = true;

  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _fetchInventoryItems();
  }

  // Fetch inventory items from Firestore
  Future<void> _fetchInventoryItems() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user-specific inventory items
      QuerySnapshot snapshot = await _inventoryCollection
          .where('userId', isEqualTo: user?.uid)
          .get();
      
      setState(() {
        _allItems = snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .toList();
        
        // Update categories
        Set<String> uniqueCategories = {'All'};
        for (var item in _allItems) {
          uniqueCategories.add(item.category);
        }
        _categories = uniqueCategories.toList();
      });

      // Check for low stock alerts after fetching items
      await checkLowStockAndNotify();
      
    } catch (e) {
      print('Error fetching inventory items: $e');
      // Handle error (show a snackbar, etc.)
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<InventoryItem> get _filteredItems {
    return _allItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _addNewItem() {
    // First check if user is authenticated
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add items')),
      );
      return;
    }
    _nameController.clear();
    _categoryController.clear();
    _quantityController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text;
              final category = _categoryController.text;
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              
              if (name.isNotEmpty && category.isNotEmpty && quantity > 0) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                try {
                  final newDoc = await _inventoryCollection.add({
                    'name': name,
                    'category': category,
                    'quantity': quantity,
                    'lastUpdated': Timestamp.now(),
                    'userId': user?.uid,
                  });

                  await logStockChange(
                    itemId: newDoc.id,
                    action: 'add',
                    name: name,
                    category: category,
                    quantityChange: quantity,
                  );

                  // Refresh items
                  await _fetchInventoryItems();
                  
                  // Close loading dialog and add dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding item: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields correctly')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = _filteredItems[index];
    _nameController.text = item.name;
    _categoryController.text = item.category;
    _quantityController.text = item.quantity.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text;
              final category = _categoryController.text;
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              
              if (name.isNotEmpty && category.isNotEmpty && quantity > 0) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                try {
                  // Update in Firestore
                  await _inventoryCollection.doc(item.id).update({
                    'name': name,
                    'category': category,
                    'quantity': quantity,
                    'lastUpdated': Timestamp.now(),
                  });
                  await logStockChange(
                    itemId: item.id,
                    action: 'update',
                    name: name,
                    category: category,
                    quantityChange: quantity - item.quantity,
                  );

                  // Refresh items and check for low stock
                  await _fetchInventoryItems();
                  
                  // Close loading dialog and edit dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item updated successfully')),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating item: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    final item = _filteredItems[index];
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show loading indicator
              Navigator.of(context).pop(); // Close confirmation dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                // Delete from Firestore
                await _inventoryCollection.doc(item.id).delete();

                await logStockChange(
                  itemId: item.id,
                  action: 'delete',
                  name: item.name,
                  category: item.category,
                  quantityChange: -item.quantity,
                );

                // Refresh items
                await _fetchInventoryItems();
                
                // Close loading dialog
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
                );
              } catch (e) {
                // Close loading dialog
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting item: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        actions: [
          IconButton(
            onPressed: checkLowStockAndNotify, // Manual low stock check
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Check Low Stock',
          ),
          IconButton(
            onPressed: _fetchInventoryItems, // Add refresh button
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: signout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Logged in as: ${user?.email}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(child: Text("No items found."))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isLowStock = _isLowStock(item.quantity);
                          final stockColor = _getStockStatusColor(item.quantity);
                          final stockStatus = _getStockStatusText(item.quantity);
                          final stockIcon = _getStockStatusIcon(item.quantity);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: isLowStock ? 4 : 2,
                            color: item.quantity == 0 
                                ? Colors.red.shade50 
                                : isLowStock 
                                    ? Colors.orange.shade50 
                                    : null,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: stockColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: stockColor.withOpacity(0.3)),
                                ),
                                child: Icon(
                                  stockIcon,
                                  color: stockColor,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.quantity == 0 ? Colors.red.shade700 : null,
                                      ),
                                    ),
                                  ),
                                  if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stockColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        stockStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${item.category}'),
                                  Row(
                                    children: [
                                      Text('Quantity: '),
                                      Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: stockColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('Last Updated: ${DateFormat.yMMMMd().format(item.lastUpdated)}'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue), 
                                    onPressed: () => _editItem(index)
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red), 
                                    onPressed: () => _deleteItem(index)
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: const Icon(Icons.add),
        tooltip: 'Add New Item',
      ),
    );
  }
}