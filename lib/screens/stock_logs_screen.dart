import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StockLogsScreen extends StatelessWidget {
  const StockLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Update Logs'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!.docs;

          if (logs.isEmpty) {
            return const Center(child: Text('No stock updates yet.'));
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final data = log.data() as Map<String, dynamic>;
              final action = data['action'] ?? 'unknown';
              final actionIcon = _getIcon(action);
              final actionColor = _getColor(action);
              final timestamp = (data['timestamp'] as Timestamp).toDate();
              final formattedDate = DateFormat('MMM d, yyyy – hh:mm a').format(timestamp);

              return ListTile(
                leading: Icon(actionIcon, color: actionColor),
                title: Text('${data['name']} (${data['category']})'),
                subtitle: Text('$action • Qty Change: ${data['quantityChange']} \n$formattedDate'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String action) {
    switch (action) {
      case 'add':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getColor(String action) {
    switch (action) {
      case 'add':
        return Colors.green;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

