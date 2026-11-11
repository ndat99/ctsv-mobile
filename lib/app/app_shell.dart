import 'package:flutter/material.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/home/presentation/home_page.dart';
import '../features/scholarships/data/scholarship_repository.dart';
import '../features/scholarships/presentation/scholarships_page.dart';
import '../features/shcn/data/schedule_repository.dart';
import '../features/shcn/presentation/schedule_page.dart';
import '../shared/widgets/feature_placeholder.dart';
import 'widgets/app_bottom_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _selectedTab = AppTab.home;
  bool _scholarshipsOpened = false;
  bool _schedulesOpened = false;
  late final _scholarships = ScholarshipRepository(widget.auth.service.api);
  late final _schedules = ScheduleRepository(widget.auth.service.api);

  void _select(AppTab tab) => setState(() {
    _selectedTab = tab;
    if (tab == AppTab.scholarships) _scholarshipsOpened = true;
    if (tab == AppTab.schedules) _schedulesOpened = true;
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
                index: _selectedTab.index,
                children: [
                  HomePage(
                    onOpenSchedules: () => _select(AppTab.schedules),
                    onOpenScholarships: () => _select(AppTab.scholarships),
                  ),
                  if (_schedulesOpened)
                    SchedulePage(
                      repository: _schedules,
                      user: widget.auth.user!,
                      active: _selectedTab == AppTab.schedules,
                    )
                  else
                    const SizedBox.shrink(),
                  if (_scholarshipsOpened)
                    ScholarshipsPage(
                      repository: _scholarships,
                      user: widget.auth.user!,
                      active: _selectedTab == AppTab.scholarships,
                    )
                  else
                    const SizedBox.shrink(),
                  const FeaturePlaceholder(
                    key: Key('training-score-page'),
                    title: 'Điểm rèn luyện',
                    icon: Icons.fact_check_outlined,
                  ),
                  const FeaturePlaceholder(
                    key: Key('tuition-reduction-page'),
                    title: 'Miễn giảm học phí',
                    icon: Icons.school_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedTab: _selectedTab,
        onSelect: _select,
      ),
    );
  }
}
