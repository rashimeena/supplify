import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedCategory = '';
  String selectedRange = 'Last 30 Days';

  List<String> categories = [];
  final List<String> dateRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  List<FlSpot> stockSpots = [];
  bool isLoading = true;
  bool isCategoryLoading = true;

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

  Future<void> fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stock_logs')
          .get();

      final Set<String> uniqueCategories = snapshot.docs
          .map((doc) => doc['category'] as String)
          .toSet();

      if (uniqueCategories.isNotEmpty) {
        setState(() {
          categories = uniqueCategories.toList()..sort();
          selectedCategory = categories.first;
          isCategoryLoading = false;
        });

        // Fetch data for default category
        fetchStockData();
      } else {
        setState(() {
          categories = [];
          isCategoryLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> fetchStockData() async {
    if (selectedCategory.isEmpty) return;

    try {
      setState(() => isLoading = true);
      final now = DateTime.now();
      final days = getRangeCount();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await FirebaseFirestore.instance
          .collection('stock_logs')
          .where('category', isEqualTo: selectedCategory)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp')
          .get();

      Map<int, double> dailyTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final quantity = (data['quantity'] as num).toDouble();

        int dayIndex = timestamp.difference(startDate).inDays;
        dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0) + quantity;
      }

      List<FlSpot> spots = dailyTotals.entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();

      setState(() {
        stockSpots = spots;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching stock data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isCategoryLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Graph", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text("Visualize your inventory data with charts and trends."),
                  const SizedBox(height: 20),

                  // Dropdown selectors
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: selectedCategory,
                        onChanged: (val) => setState(() {
                          selectedCategory = val!;
                          fetchStockData();
                        }),
                        items: categories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: selectedRange,
                        onChanged: (val) => setState(() {
                          selectedRange = val!;
                          fetchStockData();
                        }),
                        items: dateRanges
                            .map((range) =>
                                DropdownMenuItem(value: range, child: Text(range)))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart section
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: (getRangeCount() ~/ 2).toDouble(),
                                    getTitlesWidget: (value, meta) => Text("Day ${value.toInt() + 1}", style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 50,
                                    getTitlesWidget: (value, meta) => Text("${value.toInt()}", style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  spots: stockSpots,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),

                  const SizedBox(height: 8),
                  Text("• $selectedCategory", style: const TextStyle(color: Colors.blue))
                ],
              ),
      ),
    );
  }
}
