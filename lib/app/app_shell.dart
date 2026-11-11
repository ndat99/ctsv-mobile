import 'package:flutter/material.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/home/presentation/home_page.dart';
import '../features/scholarships/data/scholarship_repository.dart';
import '../features/scholarships/presentation/scholarships_page.dart';
import '../features/shcn/data/schedule_repository.dart';
import '../features/shcn/presentation/schedule_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _scholarshipsOpened = false;
  bool _schedulesOpened = false;
  late final _scholarships = ScholarshipRepository(widget.auth.service.api);
  late final _schedules = ScheduleRepository(widget.auth.service.api);

  void _select(int index) => setState(() {
    _selectedIndex = index;
    if (index == 2) _scholarshipsOpened = true;
    if (index == 1) _schedulesOpened = true;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTSV DUT'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.school_outlined),
        ),
        actions: [
          IconButton(
            key: const Key('logout'),
            tooltip: 'Đăng xuất',
            onPressed: widget.auth.busy ? null : widget.auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text('Xin chào, ${widget.auth.user!.username}'),
            ),
            if (widget.auth.message != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.auth.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  HomePage(
                    onOpenSchedules: () => _select(1),
                    onOpenScholarships: () => _select(2),
                  ),
                  if (_schedulesOpened)
                    SchedulePage(
                      repository: _schedules,
                      user: widget.auth.user!,
                      active: _selectedIndex == 1,
                    )
                  else
                    const SizedBox.shrink(),
                  if (_scholarshipsOpened)
                    ScholarshipsPage(
                      repository: _scholarships,
                      user: widget.auth.user!,
                      active: _selectedIndex == 2,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
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
