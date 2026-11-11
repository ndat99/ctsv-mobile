import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_message.dart';
import '../../auth/data/auth_user.dart';
import '../data/schedule_repository.dart';
import 'schedule_card.dart';
import 'schedule_detail_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.repository,
    required this.user,
    this.active = true,
  });

  final ScheduleRepository repository;
  final AuthUser user;
  final bool active;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  ScheduleResult? _data;
  String? _error;
  bool _loading = true;
  int _request = 0;
  int _requestedPage = 0;
  int? _selectedId;
  final _scroll = ScrollController();

  String? get _accessMessage {
    if (!widget.user.permissions.contains('SHCN_LICH_XEM')) {
      return 'Tài khoản chưa được cấp quyền xem lịch SHCN.';
    }
    if ((widget.user.studentProfileId ?? 0) <= 0) {
      return 'Tài khoản chưa liên kết hồ sơ sinh viên hợp lệ. '
          'Vui lòng liên hệ quản trị viên.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_accessMessage == null) unawaited(_load(0));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    final request = ++_request;
    setState(() {
      _requestedPage = page;
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.list(page: page);
      if (!mounted || request != _request) return;
      setState(() => _data = result);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = scheduleErrorMessage(error));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _back() => setState(() => _selectedId = null);

  @override
  Widget build(BuildContext context) {
    final accessMessage = _accessMessage;
    return PopScope(
      canPop: !widget.active || _selectedId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.active && _selectedId != null) _back();
      },
      child: _selectedId != null
          ? ScheduleDetailPage(
              key: ValueKey(_selectedId),
              repository: widget.repository,
              id: _selectedId!,
              onBack: _back,
            )
          : Column(
              key: const Key('schedule-page'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lịch sinh hoạt chủ nhiệm',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (accessMessage == null)
                        IconButton(
                          key: const Key('schedules-refresh'),
                          tooltip: 'Làm mới danh sách lịch',
                          onPressed: _loading ? null : () => _load(0),
                          icon: const Icon(Icons.refresh),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: accessMessage != null
                      ? FeatureMessage(
                          message: accessMessage,
                          icon: Icons.lock_outline,
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(0),
                          child: ListView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              const Text(
                                'Lịch SHCN của lớp trong phạm vi tài khoản của bạn.',
                              ),
                              const SizedBox(height: 16),
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_error != null)
                                FeatureMessage(
                                  message: _error!,
                                  onRetry: () => _load(_requestedPage),
                                )
                              else if (_data != null) ...[
                                Text('Tổng ${_data!.total} lịch'),
                                const SizedBox(height: 12),
                                if (_data!.items.isEmpty)
                                  const FeatureMessage(
                                    icon: Icons.event_busy_outlined,
                                    message: 'Chưa có lịch SHCN ở trang này trong phạm vi được xem.',
                                  ),
                                for (final item in _data!.items)
                                  ScheduleCard(
                                    item: item,
                                    onOpen: () =>
                                        setState(() => _selectedId = item.id),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      key: const Key('schedules-previous'),
                                      onPressed: _data!.page > 0
                                          ? () => _load(_data!.page - 1)
                                          : null,
                                      child: const Text('Trước'),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Trang ${_data!.page + 1}/${_data!.pageCount}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    OutlinedButton(
                                      key: const Key('schedules-next'),
                                      onPressed: _data!.hasNext
                                          ? () => _load(_data!.page + 1)
                                          : null,
                                      child: const Text('Sau'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
