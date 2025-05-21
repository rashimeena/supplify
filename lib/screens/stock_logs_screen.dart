import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart';

class StockLogsScreen extends StatelessWidget {
  const StockLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view logs.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Update Logs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock_logs')
            .where('userId', isEqualTo: currentUser.uid) // Filter by userId
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index].data() as Map<String, dynamic>;

              DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
              String dateStr = DateFormat.yMMMMd().add_jm().format(timestamp);

              return ListTile(
                title: Text(log['item'] ?? 'Unknown item'),
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
