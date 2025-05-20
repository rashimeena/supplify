import 'package:flutter/material.dart';
import 'package:supplify/screens/category_distribution_screen.dart';
import 'package:supplify/screens/homescreen.dart';
import 'package:supplify/screens/analytics_screen.dart';
import 'package:supplify/screens/settings_screen.dart';
import 'package:supplify/screens/stock_logs_screen.dart';

 // Make sure path is correct

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Homescreen(),
    AnalyticsScreen(),
    CategoryDistributionScreen(),
    // PlaceholderScreen(title: 'Graph'),
    StockLogsScreen(),
    // PlaceholderScreen(title: 'Stock Status'),
     SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics),label: 'Analytics',),
           BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Category'),
          // BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Graph'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt),label: 'Logs',),
          // BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'Settings',),

 

        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Section Coming Soon!', style: TextStyle(fontSize: 18))),
    );
  }
}





