import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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

  //alert ke liye 
  Future<void> checkLowStockAndNotify() async {
  try {
    // Ensure user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // Get settings
    final settingsDoc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('app_config')
        .get();

    final settings = settingsDoc.data();
    if (settings == null) return;

    final threshold = settings['lowStockThreshold'] ?? 5;
    final showAlerts = settings['showAlerts'] ?? false;

    if (!showAlerts) return;

    // Query inventory for low stock
    final lowStockSnapshot = await FirebaseFirestore.instance
        .collection('inventory') // Change to your inventory collection name
        .where('quantity', isLessThanOrEqualTo: threshold)
        .get();

    if (lowStockSnapshot.docs.isNotEmpty) {
      // Collect item names
      final itemNames = lowStockSnapshot.docs
          .map((doc) => doc['name'] ?? 'Unnamed Item')
          .join(', ');

      // Show in-app alert
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


  @override
  void initState() {
    super.initState();
    _fetchInventoryItems();
    checkLowStockAndNotify();
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
                  // Add to Firestore
                  // await _inventoryCollection.add({
                  //   'name': name,
                  //   'category': category,
                  //   'quantity': quantity,
                  //   'lastUpdated': Timestamp.now(),
                  //   'userId': user?.uid, // Associate with the current user
                  // });

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

                  
                  // Refresh items
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
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                'Category: ${item.category}\nQuantity: ${item.quantity}\nLast Updated: ${DateFormat.yMMMMd().format(item.lastUpdated)}',
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editItem(index)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(index)),
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