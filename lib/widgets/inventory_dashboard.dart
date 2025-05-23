import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supplify/screens/homescreen.dart'; // If you're using DateFormat here
//import '../models/inventory_item.dart'; // Adjust the path based on your project structure

class InventoryDashboard extends StatelessWidget {
  final String? userEmail;
  final bool isLoading;
  final List<InventoryItem> filteredItems;
  final List<String> categories;
  final String selectedCategory;
  final TextEditingController searchController;
  final void Function() fetchInventoryItems;
  final void Function() checkLowStockAndNotify;
  final void Function() signOut;
  final void Function(int index) editItem;
  final void Function(int index) deleteItem;
  final void Function() addNewItem;
  final void Function(String?) onCategoryChanged;
  final void Function(String) onSearchChanged;
  final bool Function(int quantity) isLowStock;
  final Color Function(int quantity) getStockStatusColor;
  final String Function(int quantity) getStockStatusText;
  final IconData Function(int quantity) getStockStatusIcon;

  const InventoryDashboard({
    super.key,
    required this.userEmail,
    required this.isLoading,
    required this.filteredItems,
    required this.categories,
    required this.selectedCategory,
    required this.searchController,
    required this.fetchInventoryItems,
    required this.checkLowStockAndNotify,
    required this.signOut,
    required this.editItem,
    required this.deleteItem,
    required this.addNewItem,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.isLowStock,
    required this.getStockStatusColor,
    required this.getStockStatusText,
    required this.getStockStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Using your specific theme colors
    const Color lightBlue = Color(0xFF8ECAE6);
    const Color blue = Color(0xFF219EBC);
    const Color darkBlue = Color(0xFF023047);
    //const Color amber = Color(0xFFFFB703);
    
    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        title: Text(
          'Inventory Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: darkBlue, // Changed to dark blue
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: checkLowStockAndNotify,
              icon: Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'Check Low Stock',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: fetchInventoryItems,
              icon: Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: signOut,
              icon: Icon(Icons.logout, color: Colors.white),
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkBlue.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        userEmail ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Filter Section - Fixed layout
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search inventory...',
                    hintStyle: TextStyle(color: darkBlue.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: blue),
                    filled: true,
                    fillColor: lightBlue.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16), // Increased spacing
                
                // Category Filter - Fixed with proper constraints
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
    value: selectedCategory == 'All' ? null : selectedCategory, // Treat 'All' as null
    hint: Text(
      'Filter by Category',
      style: TextStyle(color: darkBlue),
    ),
    isExpanded: true,
    icon: Icon(Icons.arrow_drop_down, color: blue),
    style: TextStyle(color: darkBlue, fontSize: 16),
    items: categories.where((cat) => cat != 'All').map((cat) => DropdownMenuItem(
      value: cat, 
      child: Text(
        cat, 
        style: TextStyle(color: darkBlue),
        overflow: TextOverflow.ellipsis,
      ),
    )).toList(),
    onChanged: (value) => onCategoryChanged(value ?? 'All'), // Pass 'All' when null is selected
    dropdownColor: Colors.white,
  ),
),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Inventory List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: blue),
                        const SizedBox(height: 16),
                        Text(
                          'Loading inventory...',
                          style: TextStyle(
                            color: darkBlue.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: darkBlue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No items found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: darkBlue.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Try adjusting your search or filter",
                              style: TextStyle(
                                fontSize: 14,
                                color: darkBlue.withValues(alpha:0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final lowStock = isLowStock(item.quantity);
                          final stockColor = getStockStatusColor(item.quantity);
                          final stockStatus = getStockStatusText(item.quantity);
                          final stockIcon = getStockStatusIcon(item.quantity);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: lowStock 
                                      ? stockColor.withValues(alpha:0.2)
                                      : blue.withValues(alpha:0.1),
                                  blurRadius: lowStock ? 12 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: lowStock 
                                  ? Border.all(color: stockColor.withValues(alpha:0.3), width: 1)
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: stockColor.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: stockColor.withValues(alpha:0.2)),
                                ),
                                child: Icon(stockIcon, color: stockColor, size: 24),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: item.quantity == 0 
                                            ? Colors.red.shade700 
                                            : darkBlue,
                                      ),
                                    ),
                                  ),
                                  if (lowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stockColor,
                                        borderRadius: BorderRadius.circular(16),
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
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 14,
                                          color: darkBlue.withValues(alpha:0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: darkBlue.withValues(alpha:0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_outlined,
                                          size: 14,
                                          color: darkBlue.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Quantity: ',
                                          style: TextStyle(
                                            color: darkBlue.withValues(alpha:0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: stockColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: darkBlue.withValues(alpha:0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat.yMMMMd().format(item.lastUpdated),
                                          style: TextStyle(
                                            color: darkBlue.withValues(alpha:0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => editItem(index),
                                      tooltip: 'Edit Item',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => deleteItem(index),
                                      tooltip: 'Delete Item',
                                    ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: lightBlue.withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: addNewItem,
          backgroundColor: lightBlue,
          foregroundColor: Colors.white70,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Add New Item',
        ),
      ),
    );
  }
}