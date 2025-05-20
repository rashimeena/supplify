import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedCategory = 'Office Supplies';
  String selectedRange = 'Last 30 Days';

  final List<String> categories = [
    'Visitor ID Cards',
    'Office Supplies',
    'Banners',
    'Stationery',
    'Electronics'
  ];

  final List<String> dateRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  List<FlSpot> generateSmoothData(int count) {
    final random = Random();
    return List.generate(count, (i) => FlSpot(i.toDouble(), 400 + random.nextInt(200).toDouble()));
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

  @override
  Widget build(BuildContext context) {
    final spots = generateSmoothData(getRangeCount());

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
                      children: [
                        DropdownButton<String>(
                          value: selectedCategory,
                          onChanged: (val) => setState(() => selectedCategory = val!),
                          items: categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )).toList(),
                        ),
                        SizedBox(width: 20),
                        DropdownButton<String>(
                          value: selectedRange,
                          onChanged: (val) => setState(() => selectedRange = val!),
                          items: dateRanges.map((range) => DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          )).toList(),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (getRangeCount() ~/ 2).toDouble(),
                                getTitlesWidget: (value, meta) {
                                  return Text("Day ${value.toInt() + 1}", style: TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 100,
                                getTitlesWidget: (value, meta) => Text("${value.toInt()}", style: TextStyle(fontSize: 10)),
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              spots: spots,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("• $selectedCategory", style: TextStyle(color: Colors.blue))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
