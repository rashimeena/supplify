import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class InventoryItem {
  String name;
  String category;
  int quantity;
  DateTime lastUpdated;

  InventoryItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.lastUpdated,
  });
}

class _HomescreenState extends State<Homescreen> {
  final user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();

  List<InventoryItem> _allItems = [
    InventoryItem(
        name: 'Printer Paper',
        category: 'Office Supplies',
        quantity: 500,
        lastUpdated: DateTime.now()),
    InventoryItem(
        name: 'Visitor ID Cards',
        category: 'IDs',
        quantity: 50,
        lastUpdated: DateTime(2025, 5, 12)),
    InventoryItem(
        name: 'Conference Banner',
        category: 'Banners',
        quantity: 5,
        lastUpdated: DateTime(2025, 5, 14)),
    InventoryItem(
        name: 'Ballpoint Pens',
        category: 'Stationery',
        quantity: 200,
        lastUpdated: DateTime(2025, 5, 5)),
    InventoryItem(
        name: 'USB Flash Drives',
        category: 'Electronics',
        quantity: 15,
        lastUpdated: DateTime(2025, 5, 8)),
  ];

  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Office Supplies', 'IDs', 'Banners', 'Stationery', 'Electronics'];

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
            onPressed: () {
              final name = _nameController.text;
              final category = _categoryController.text;
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              if (name.isNotEmpty && category.isNotEmpty && quantity > 0) {
                setState(() {
                  _allItems.add(InventoryItem(
                      name: name,
                      category: category,
                      quantity: quantity,
                      lastUpdated: DateTime.now()));
                  if (!_categories.contains(category)) {
                    _categories.add(category);
                  }
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = _filteredItems[index];
    final realIndex = _allItems.indexOf(item);
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
            onPressed: () {
              final name = _nameController.text;
              final category = _categoryController.text;
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              if (name.isNotEmpty && category.isNotEmpty && quantity > 0) {
                setState(() {
                  _allItems[realIndex] = InventoryItem(
                      name: name,
                      category: category,
                      quantity: quantity,
                      lastUpdated: DateTime.now());
                  if (!_categories.contains(category)) {
                    _categories.add(category);
                  }
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    final item = _filteredItems[index];
    setState(() => _allItems.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        actions: [
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
            child: _filteredItems.isEmpty
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
