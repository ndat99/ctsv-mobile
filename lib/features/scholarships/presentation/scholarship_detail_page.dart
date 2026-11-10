import 'dart:async';

import 'package:flutter/material.dart';

import '../data/scholarship_announcement.dart';
import '../data/scholarship_repository.dart';
import 'scholarship_format.dart';
import 'scholarship_widgets.dart';

class ScholarshipDetailPage extends StatefulWidget {
  const ScholarshipDetailPage({
    super.key,
    required this.repository,
    required this.id,
    required this.onBack,
  });

  final ScholarshipRepository repository;
  final int id;
  final VoidCallback onBack;

  @override
  State<ScholarshipDetailPage> createState() => _ScholarshipDetailPageState();
}

class _ScholarshipDetailPageState extends State<ScholarshipDetailPage> {
  ScholarshipAnnouncement? _item;
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
      setState(() => _error = scholarshipErrorMessage(error));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('scholarship-detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('scholarship-back'),
              tooltip: 'Về danh sách thông báo',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Chi tiết thông báo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              key: const Key('scholarship-detail-refresh'),
              tooltip: 'Làm mới thông báo',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  ScholarshipMessage(message: _error!, onRetry: _load)
                else if (_item != null)
                  _Details(item: _item!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.item});

  final ScholarshipAnnouncement item;

  @override
  Widget build(BuildContext context) {
    final content = scholarshipContent(item.conditions);
    final form = item.form;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ScholarshipAcceptance(accepting: item.acceptingApplications),
        ),
        const SizedBox(height: 16),
        SelectableText(
          item.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Info(label: 'Nhà tài trợ', value: item.sponsor),
                _Info(label: 'Năm học', value: item.schoolYear),
                _Info(
                  label: 'Giá trị học bổng',
                  value: scholarshipMoney(item.amount),
                ),
                _Info(
                  label: 'Mở nhận hồ sơ',
                  value: scholarshipDateTime(item.opensAt),
                ),
                _Info(
                  label: 'Hạn nộp hồ sơ',
                  value: scholarshipDateTime(item.deadline),
                ),
                _Info(label: 'Trạng thái', value: scholarshipState(item.state)),
                const Text('Thời gian theo giờ Việt Nam (UTC+7).'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Nội dung và điều kiện',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SelectableText(
          content.trim().isEmpty ? 'Chưa có nội dung điều kiện.' : content,
        ),
        const SizedBox(height: 24),
        Text(
          'Thông tin cần chuẩn bị',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (form == null)
          const Text('Chưa có thông tin biểu mẫu kèm theo.')
        else ...[
          Text('${form.name} · Phiên bản ${form.version}'),
          const SizedBox(height: 8),
          if (form.fields.isEmpty)
            const Text('Biểu mẫu chưa có trường thông tin.'),
          for (final field in form.fields)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${field.label}${field.required ? ' (Bắt buộc)' : ' (Không bắt buộc)'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(scholarshipFieldDescription(field)),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
