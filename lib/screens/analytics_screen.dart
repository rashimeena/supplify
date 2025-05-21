import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedCategory = 'Office Supplies';
  String selectedRange = 'Last 30 Days';
  bool isLoading = true;
  List<Map<String, dynamic>> inventoryData = [];
  bool hasData = false;
  List<String> categories = []; // Will contain both predefined and user-defined

  final List<String> dateRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  final List<String> predefinedCategories = [
    'Visitor ID Cards',
    'Office Supplies',
    'Banners',
    'Stationery',
    'Electronics',
  ];

  @override
  void initState() {
    super.initState();
    loadCategoriesAndData();
  }

  Future<void> loadCategoriesAndData() async {
    await fetchCategories();
    await fetchInventoryData();
  }

  Future<void> fetchCategories() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in.");
      return;
    }

    final userId = user.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .get();

    final allCategories = snapshot.docs
        .map((doc) => doc['category'] as String)
        .toSet();

    final mergedCategories = {...predefinedCategories, ...allCategories};

    setState(() {
      categories = mergedCategories.toList();
      if (!categories.contains(selectedCategory)) {
        selectedCategory = categories.first;
      }
    });
  } catch (e) {
    print('Error fetching user categories: $e');
    setState(() {
      categories = predefinedCategories;
    });
  }
}


  int getRangeCount() {
    switch (selectedRange) {
      case 'Last 7 Days':
        return 7;
      case 'Last 30 Days':
        return 30;
      case 'Last 90 Days':
        return 90;
      default:
        return 30;
    }
  }

  DateTime getStartDate() {
    final now = DateTime.now();
    switch (selectedRange) {
      case 'Last 7 Days':
        return now.subtract(Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(Duration(days: 30));
      case 'Last 90 Days':
        return now.subtract(Duration(days: 90));
      default:
        return now.subtract(Duration(days: 30));
    }
  }

  Future<void> fetchInventoryData() async {
    setState(() {
      isLoading = true;
      hasData = false;
    });

    try {
      final inventoryRef = FirebaseFirestore.instance.collection('inventory');
      final user = FirebaseAuth.instance.currentUser;
if (user == null) return;

final querySnapshot = await inventoryRef
  .where('category', isEqualTo: selectedCategory)
  .where('userId', isEqualTo: user.uid)
  .get();

      final startDate = getStartDate();
      final List<Map<String, dynamic>> processedData = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        DateTime updateDate;

        if (data['lastUpdated'] is Timestamp) {
          updateDate = (data['lastUpdated'] as Timestamp).toDate();
        } else if (data['lastUpdated'] is String) {
          try {
            updateDate = DateTime.parse(data['lastUpdated']);
          } catch (e) {
            continue;
          }
        } else {
          updateDate = DateTime.now();
        }

        int quantity = 0;
        if (data['quantity'] is int) {
          quantity = data['quantity'];
        } else if (data['quantity'] is String) {
          quantity = int.tryParse(data['quantity']) ?? 0;
        }

        if (updateDate.isAfter(startDate)) {
          processedData.add({
            'date': updateDate,
            'quantity': quantity,
            'name': data['name'] ?? 'Unknown Item',
            'id': doc.id,
          });
        }
      }

      processedData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      setState(() {
        inventoryData = processedData;
        hasData = processedData.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching inventory data: $e');
      setState(() {
        isLoading = false;
        hasData = false;
      });
    }
  }

  List<FlSpot> getDataSpots() {
    if (inventoryData.isEmpty) return [FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0)];

    final Map<String, int> dailyTotals = {};
    final startDate = getStartDate();
    final now = DateTime.now();

    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      final day = startDate.add(Duration(days: i));
      dailyTotals[DateFormat('yyyy-MM-dd').format(day)] = 0;
    }

    for (var item in inventoryData) {
      final day = DateFormat('yyyy-MM-dd').format(item['date'] as DateTime);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + (item['quantity'] as int);
    }

    final List<FlSpot> spots = [];
    final sortedDays = dailyTotals.keys.toList()..sort();

    for (int i = 0; i < sortedDays.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTotals[sortedDays[i]]!.toDouble()));
    }

    return spots;
  }

  String formatDateLabel(double value, List<String> days) {
    if (days.isEmpty || value.toInt() >= days.length || value.toInt() < 0) return '';
    final day = DateTime.parse(days[value.toInt()]);
    return DateFormat('MM/dd').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final spots = getDataSpots();
    final startDate = getStartDate();
    final now = DateTime.now();
    final List<String> sortedDays = [];

    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      final day = startDate.add(Duration(days: i));
      sortedDays.add(DateFormat('yyyy-MM-dd').format(day));
    }

    sortedDays.sort();

    double maxY = 10;
    if (spots.isNotEmpty) {
      maxY = spots.map((spot) => spot.y).reduce(max);
      maxY = maxY * 1.1;
      maxY = maxY < 10 ? 10 : maxY;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Graph", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 4),
            Text("Visualize your inventory data with charts and trends."),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Stock History", style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: selectedCategory,
                          onChanged: (val) {
                            if (val != null && val != selectedCategory) {
                              setState(() => selectedCategory = val);
                              fetchInventoryData();
                            }
                          },
                          items: categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )).toList(),
                        ),
                        DropdownButton<String>(
                          value: selectedRange,
                          onChanged: (val) {
                            if (val != null && val != selectedRange) {
                              setState(() => selectedRange = val);
                              fetchInventoryData();
                            }
                          },
                          items: dateRanges.map((range) => DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          )).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    isLoading
                        ? Center(child: Container(height: 250, child: CircularProgressIndicator()))
                        : Container(
                            height: 250,
                            child: hasData
                                ? LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        horizontalInterval: maxY / 5,
                                        verticalInterval: 1,
                                      ),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: max(1, spots.length / 5).toDouble(),
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= sortedDays.length || value < 0) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  formatDateLabel(value, sortedDays),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: maxY / 5,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
                                      minX: 0,
                                      maxX: spots.length - 1.0,
                                      minY: 0,
                                      maxY: maxY,
                                      lineBarsData: [
                                        LineChartBarData(
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: spots.length < 15),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.blue.withOpacity(0.2),
                                          ),
                                          spots: spots,
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bar_chart_outlined, size: 50, color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text("No data available for the selected category and time range",
                                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                          ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                            SizedBox(width: 8),
                            Text(selectedCategory),
                          ],
                        ),
                        Text("Total Items: ${hasData ? inventoryData.fold(0, (int sum, item) => sum + (item['quantity'] as int)) : 0}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (inventoryData.isNotEmpty && !isLoading) ...[
              SizedBox(height: 20),
              Text("Recent Updates", style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: min(5, inventoryData.length),
                  itemBuilder: (context, index) {
                    final sortedData = List<Map<String, dynamic>>.from(inventoryData)
                      ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                    final item = sortedData[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['name']),
                        subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(item['date'] as DateTime)),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("Qty: ${item['quantity']}", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
