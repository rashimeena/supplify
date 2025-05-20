import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StockLogsScreen extends StatelessWidget {
  const StockLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Update Logs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index].data() as Map<String, dynamic>;

              DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
              String dateStr = DateFormat.yMMMMd().add_jm().format(timestamp);

              return ListTile(
                title: Text('${log['item']}'),
                subtitle: Text(dateStr),
                trailing: Text(
                  '${log['change'] > 0 ? '+' : ''}${log['change']}',
                  style: TextStyle(
                    color: log['change'] > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
