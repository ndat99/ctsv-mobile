import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_message.dart';
import '../../auth/data/auth_user.dart';
import '../data/scholarship_announcement.dart';
import '../data/scholarship_repository.dart';
import 'scholarship_detail_page.dart';
import 'scholarship_format.dart';
import 'scholarship_widgets.dart';

class ScholarshipsPage extends StatefulWidget {
  const ScholarshipsPage({
    super.key,
    required this.repository,
    required this.user,
    this.active = true,
  });

  final ScholarshipRepository repository;
  final AuthUser user;
  final bool active;

  @override
  State<ScholarshipsPage> createState() => _ScholarshipsPageState();
}

class _ScholarshipsPageState extends State<ScholarshipsPage> {
  ScholarshipPage? _data;
  String? _error;
  bool _loading = true;
  int _request = 0;
  int _requestedPage = 0;
  int? _selectedId;
  String _keyword = '';
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  String? get _accessMessage {
    if (!widget.user.permissions.contains('HB_TT_XEM')) {
      return 'Tài khoản chưa có quyền xem thông báo học bổng tài trợ.';
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
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load(int page, {String? query}) async {
    final request = ++_request;
    final keyword = query ?? _keyword;
    setState(() {
      _keyword = keyword;
      _requestedPage = page;
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.list(page: page, query: keyword);
      if (!mounted || request != _request) return;
      setState(() => _data = result);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = scholarshipErrorMessage(error));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _search() {
    final keyword = _searchController.text.trim();
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    FocusScope.of(context).unfocus();
    unawaited(_load(0, query: keyword));
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    unawaited(_load(0, query: ''));
  }

  void _changePage(int page) {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    unawaited(_load(page, query: ''));
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
          ? ScholarshipDetailPage(
              key: ValueKey(_selectedId),
              repository: widget.repository,
              id: _selectedId!,
              onBack: _back,
            )
          : Column(
              key: const Key('scholarships-page'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Thông báo học bổng',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (accessMessage == null)
                        IconButton(
                          key: const Key('scholarships-refresh'),
                          tooltip: 'Làm mới danh sách',
                          onPressed: _loading ? null : () => _load(0),
                          icon: const Icon(Icons.refresh),
                        ),
                    ],
                  ),
                ),
                if (accessMessage == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('scholarships-search'),
                          controller: _searchController,
                          maxLength: 200,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm học bổng',
                            hintText: 'Tên học bổng hoặc nhà tài trợ',
                            counterText: '',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon:
                                _searchController.text.isNotEmpty ||
                                    _keyword.isNotEmpty
                                ? IconButton(
                                    key: const Key('scholarships-search-clear'),
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: _clearSearch,
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            key: const Key('scholarships-search-submit'),
                            onPressed: _search,
                            icon: const Icon(Icons.search),
                            label: const Text('Tìm kiếm'),
                          ),
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
                                'Học bổng tài trợ dành cho sinh viên. '
                                'Thời gian hiển thị theo giờ Việt Nam (UTC+7).',
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
                                if (_data!.items.isEmpty)
                                  FeatureMessage(
                                    icon: _keyword.isEmpty
                                        ? Icons.campaign_outlined
                                        : Icons.search_off,
                                    message: _keyword.isEmpty
                                        ? 'Chưa có thông báo học bổng '
                                              'được công khai ở trang này.'
                                        : 'Không tìm thấy học bổng phù hợp '
                                              'với tên học bổng hoặc nhà tài trợ.',
                                  ),
                                for (final item in _data!.items)
                                  _AnnouncementCard(
                                    item: item,
                                    onOpen: () =>
                                        setState(() => _selectedId = item.id),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      key: const Key('scholarships-previous'),
                                      onPressed: _data!.page > 0
                                          ? () => _changePage(_data!.page - 1)
                                          : null,
                                      child: const Text('Trước'),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Trang ${_data!.page + 1}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    OutlinedButton(
                                      key: const Key('scholarships-next'),
                                      onPressed: _data!.hasNext
                                          ? () => _changePage(_data!.page + 1)
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

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.onOpen});

  final ScholarshipAnnouncement item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('scholarship-${item.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScholarshipAcceptance(accepting: item.acceptingApplications),
              const SizedBox(height: 12),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('${item.sponsor} · ${item.schoolYear}'),
              const SizedBox(height: 12),
              Text(
                scholarshipMoney(item.amount),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text('Hạn nộp: ${scholarshipDateTime(item.deadline)}'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Text('Xem chi tiết'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
