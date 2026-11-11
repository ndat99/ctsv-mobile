import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_message.dart';
import '../data/schedule_repository.dart';
import '../data/shcn_schedule.dart';
import 'schedule_card.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({
    super.key,
    required this.repository,
    required this.id,
    required this.onBack,
  });

  final ScheduleRepository repository;
  final int id;
  final VoidCallback onBack;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  ShcnSchedule? _item;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await widget.repository.detail(widget.id);
      if (!mounted || request != _request) return;
      setState(() => _item = item);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = scheduleErrorMessage(error));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('schedule-detail'),
    children: [
      Row(
        children: [
          IconButton(
            key: const Key('schedule-back'),
            tooltip: 'Về danh sách lịch',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Chi tiết lịch SHCN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('schedule-detail-refresh'),
            tooltip: 'Làm mới lịch',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                FeatureMessage(message: _error!, onRetry: _load)
              else if (_item != null)
                ScheduleCard(item: _item!),
            ],
          ),
        ),
      ),
    ],
  );
}
