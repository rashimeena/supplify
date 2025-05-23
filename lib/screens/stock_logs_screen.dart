import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:supplify/utils/colors.dart';
import 'package:supplify/utils/theme.dart';
// import 'colors.dart'; // Import your colors file
// import 'theme.dart'; // Import your theme file

class StockLogsScreen extends StatelessWidget {
  const StockLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(AppTheme.spacingL),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  Text(
                    "User not authenticated",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock Update Logs'),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.textOnPrimary,
      ),

      
      body: StreamBuilder(
        
        stream: FirebaseFirestore.instance
            .collection('stock_logs')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final logs = snapshot.data!.docs;

          if (logs.isEmpty) {
            return _buildEmptyState(context);
          }

          // Manual sort by timestamp in descending order
          logs.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp).toDate();
            final bTime = (b['timestamp'] as Timestamp).toDate();
            return bTime.compareTo(aTime); // descending
          });

          return _buildLogsList(context, logs);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(AppTheme.spacingL),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              SizedBox(height: AppTheme.spacingM),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.spacingS),
              Text(
                'Please try again later',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: AppTheme.spacingL),
          Text(
            'Loading stock logs...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(AppTheme.spacingL),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              SizedBox(height: AppTheme.spacingL),
              Text(
                'No stock updates yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.spacingS),
              Text(
                'Stock update logs will appear here when you make changes to your inventory',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<QueryDocumentSnapshot> logs) {
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingM),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final data = log.data() as Map;
        final action = data['action'] ?? 'unknown';
        final actionIcon = _getIcon(action);
        final actionColor = _getColor(action);
        final actionBackgroundColor = _getBackgroundColor(action);
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final formattedDate = DateFormat('MMM d, yyyy – hh:mm a').format(timestamp);
        final quantityChange = data['quantityChange'] ?? 0;
        final productName = data['name'] ?? 'Unknown Product';
        final category = data['category'] ?? 'Unknown Category';

        return Card(
          margin: EdgeInsets.only(bottom: AppTheme.spacingM),
          elevation: AppTheme.elevationS,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: actionBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                  child: Icon(
                    actionIcon,
                    color: actionColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.spacingM),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildActionChip(context, action),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingXS),
                      
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: _getQuantityChangeColor(quantityChange),
                          ),
                          SizedBox(width: AppTheme.spacingXS),
                          Text(
                            'Qty Change: ${quantityChange > 0 ? '+' : ''}$quantityChange',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getQuantityChangeColor(quantityChange),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          SizedBox(width: AppTheme.spacingXS),
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionChip(BuildContext context, String action) {
    final color = _getColor(action);
    final backgroundColor = _getBackgroundColor(action);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        action.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  IconData _getIcon(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColor(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return AppColors.inStock;
      case 'update':
        return AppColors.lowStock;
      case 'delete':
        return AppColors.outOfStock;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getBackgroundColor(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return AppColors.inStockBackground;
      case 'update':
        return AppColors.lowStockBackground;
      case 'delete':
        return AppColors.outOfStockBackground;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _getQuantityChangeColor(int quantityChange) {
    if (quantityChange > 0) {
      return AppColors.inStock;
    } else if (quantityChange < 0) {
      return AppColors.outOfStock;
    } else {
      return AppColors.textSecondary;
    }
  }
}