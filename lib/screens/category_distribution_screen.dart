import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryDistributionScreen extends StatefulWidget {
  @override
  _CategoryDistributionScreenState createState() => _CategoryDistributionScreenState();
}

class _CategoryDistributionScreenState extends State<CategoryDistributionScreen> {
  Map<String, double> categoryData = {};
  bool isLoading = true;

  final Map<String, Color> categoryColors = {
    'Office Supplies': Colors.blue,
    'IDs': Colors.green,
    'Banners': Colors.orange,
    'Stationery': Colors.red,
    'Electronics': Colors.purple,
  };

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    fetchCategoryData();
  }

  Future<void> fetchCategoryData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not logged in.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userId = currentUser.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, double> tempData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String category = data['category'] ?? 'Unknown';
        double quantity = (data['quantity'] is int)
            ? (data['quantity'] as int).toDouble()
            : (data['quantity'] ?? 0).toDouble();

        // Assign a color if it's a new category
        if (!categoryColors.containsKey(category)) {
          categoryColors[category] = _generateRandomColor();
        }

        tempData[category] = (tempData[category] ?? 0) + quantity;
      }

      setState(() {
        categoryData = tempData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _generateRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(200),
      _random.nextInt(200),
      _random.nextInt(200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Category Distribution")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : categoryData.isEmpty
              ? Center(child: Text("No data found."))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Breakdown of inventory items by category",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: categoryData.keys.map((category) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: categoryColors[category] ?? Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(category),
                            ],
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = categoryData.values.fold(0.0, (a, b) => a + b);
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: categoryColors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
