import 'package:flutter/material.dart';

import '../features/home/presentation/home_page.dart';
import '../features/scholarships/presentation/scholarships_page.dart';
import '../features/shcn/presentation/schedule_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTSV DUT'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.school_outlined),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(
              onOpenSchedules: () => _select(1),
              onOpenScholarships: () => _select(2),
            ),
            const SchedulePage(),
            const ScholarshipsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            key: Key('nav-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            key: Key('nav-schedules'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch SHCN',
          ),
          NavigationDestination(
            key: Key('nav-scholarships'),
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Học bổng',
          ),
        ],
      ),
    );
  }
}
