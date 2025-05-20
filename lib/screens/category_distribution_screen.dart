import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryDistributionScreen extends StatelessWidget {
  final Map<String, double> categoryData = {
    'Office Supplies': 20,
    'IDs': 20,
    'Banners': 20,
    'Stationery': 20,
    'Electronics': 20,
  };

  final List<Color> categoryColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Category Distribution")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Breakdown of inventory items by category",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: categoryData.entries.map((entry) {
                    int index = categoryData.keys.toList().indexOf(entry.key);
                    return PieChartSectionData(
                      color: categoryColors[index],
                      value: entry.value,
                      title: "${entry.value.toInt()}%",
                      radius: 80,
                      titleStyle: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: List.generate(categoryData.length, (index) {
                String category = categoryData.keys.elementAt(index);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: categoryColors[index],
                    ),
                    SizedBox(width: 8),
                    Text(category),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class CategoryDistributionScreen extends StatelessWidget {
//   final Map<String, double> categoryQuantities = {
//     'Office Supplies': 120,
//     'IDs': 80,
//     'Banners': 50,
//     'Stationery': 100,
//     'Electronics': 150,
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Category Distribution')),
//       body: Center(
//         child: PieChart(
//           PieChartData(
//             sections: categoryQuantities.entries.map((entry) {
//               final total = categoryQuantities.values.reduce((a, b) => a + b);
//               final percentage = (entry.value / total) * 100;
//               return PieChartSectionData(
//                 title: '${percentage.toStringAsFixed(1)}%',
//                 value: entry.value,
//                 color: _getColor(entry.key),
//                 radius: 80,
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getColor(String category) {
//     switch (category) {
//       case 'Office Supplies':
//         return Colors.blue;
//       case 'IDs':
//         return Colors.green;
//       case 'Banners':
//         return Colors.orange;
//       case 'Stationery':
//         return Colors.red;
//       case 'Electronics':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }
// }

