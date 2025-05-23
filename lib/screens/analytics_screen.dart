import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart';
import 'dart:math';
// import 'colors.dart'; // Import your colors file
// import 'theme.dart'; // Import your theme file

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

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton<T>(
    T value,
    List<T> items,
    String label,
    Function(T?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            // fontSize: 12,
            color: AppColors.textPrimary,
          ),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(
              //  style: const TextStyle(fontSize: 12),
              item.toString()),
          )).toList(),
        ),
      ),
    );
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

    final totalItems = hasData 
        ? inventoryData.fold(0, (int sum, item) => sum + (item['quantity'] as int))
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Analytics Dashboard",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              "Inventory Analytics",
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              "Track your inventory trends and performance metrics",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Stats Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    "Total Items",
                    totalItems.toString(),
                    Icons.inventory_2_outlined,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatsCard(
                    "Category",
                    selectedCategory,
                    Icons.category_outlined,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Chart Section
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Stock History",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              "Trending",
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Filter Controls
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Category",
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildDropdownButton<String>(
                              selectedCategory,
                              categories,
                              "Category",
                              (val) {
                                if (val != null && val != selectedCategory) {
                                  setState(() => selectedCategory = val);
                                  fetchInventoryData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Time Range",
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildDropdownButton<String>(
                              selectedRange,
                              dateRanges,
                              "Range",
                              (val) {
                                if (val != null && val != selectedRange) {
                                  setState(() => selectedRange = val);
                                  fetchInventoryData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Chart Container
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  "Loading analytics...",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : hasData
                            ? LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: maxY / 5,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: AppColors.border.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: AppColors.border.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
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
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
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
                                          return Text(
                                            value.toInt().toString(),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                  ),
                                  minX: 0,
                                  maxX: spots.length - 1.0,
                                  minY: 0,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: spots.length < 15,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                            strokeColor: AppColors.cardBackground,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            AppColors.primary.withOpacity(0.3),
                                            AppColors.primary.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
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
                                    Container(
                                      padding: const EdgeInsets.all(AppTheme.spacingL),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.bar_chart_outlined,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingM),
                                    Text(
                                      "No Data Available",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingS),
                                    Text(
                                      "No inventory data found for the selected\ncategory and time range",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  
                  // Chart Legend
                  const SizedBox(height: AppTheme.spacingL),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(
                              selectedCategory,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: Text(
                            "Total: $totalItems items",
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent Updates Section
            if (inventoryData.isNotEmpty && !isLoading) ...[
              const SizedBox(height: AppTheme.spacingXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Updates",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to full history or refresh
                      fetchInventoryData();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Refresh"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(5, inventoryData.length),
                separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingS),
                itemBuilder: (context, index) {
                  final sortedData = List<Map<String, dynamic>>.from(inventoryData)
                    ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                  final item = sortedData[index];
                  
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(item['date'] as DateTime),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: Text(
                            "Qty: ${item['quantity']}",
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }
}