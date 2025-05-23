import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart'; // Import your colors file

class CategoryDistributionScreen extends StatefulWidget {
  const CategoryDistributionScreen({super.key});

  @override
  _CategoryDistributionScreenState createState() => _CategoryDistributionScreenState();
}

class _CategoryDistributionScreenState extends State<CategoryDistributionScreen>
    with TickerProviderStateMixin {
  Map<String, double> categoryData = {};
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, Color> categoryColors = {
    'Office Supplies': AppColors.primary,
    'IDs': AppColors.inStock,
    'Banners': AppColors.lowStock,
    'Stationery': AppColors.error,
    'Electronics': AppColors.secondary,
  };

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchCategoryData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

      // Start animation after data is loaded
      if (categoryData.isNotEmpty) {
        _animationController.forward();
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _generateRandomColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.inStock,
      AppColors.lowStock,
      AppColors.error,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String category, Color color, double value, double total) {
    final percentage = (value / total) * 100;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toInt()} items • ${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = categoryData.values.fold(0.0, (a, b) => a + b);
    final totalCategories = categoryData.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Category Distribution",
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.darkNavy,
        
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                categoryData.clear();
              });
              _animationController.reset();
              fetchCategoryData();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Loading category data...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : categoryData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXL),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                        ),
                        child: Icon(
                          Icons.pie_chart_outline,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text(
                        'No Data Available',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Add some inventory items to see the distribution',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: AppTheme.responsivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Text(
                          'Inventory Overview',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Breakdown of your inventory items by category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Items',
                                totalItems.toInt().toString(),
                                Icons.inventory_2_outlined,
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: _buildStatCard(
                                'Categories',
                                totalCategories.toString(),
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
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pie_chart,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text(
                                    'Distribution Chart',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              SizedBox(
                                height: 300,
                                child: PieChart(
                                  PieChartData(
                                    sections: _buildPieChartSections(),
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 60,
                                    borderData: FlBorderData(show: false),
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        // Add touch feedback if needed
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXL),

                        // Legend Section
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text(
                                    'Category Breakdown',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              ...categoryData.entries.map((entry) {
                                return _buildLegendItem(
                                  entry.key,
                                  categoryColors[entry.key] ?? AppColors.textSecondary,
                                  entry.value,
                                  totalItems,
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXL),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = categoryData.values.fold(0.0, (a, b) => a + b);
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: categoryColors[entry.key] ?? AppColors.textSecondary,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }
}