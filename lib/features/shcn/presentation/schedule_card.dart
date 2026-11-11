import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/date_format.dart';
import '../data/shcn_schedule.dart';
import 'schedule_format.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.item, this.onOpen});

  final ShcnSchedule item;
  final VoidCallback? onOpen;
  bool get _detail => onOpen == null;

  Future<void> _copyLink(BuildContext context, String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã sao chép link họp')));
    } on PlatformException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa sao chép được link. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final link = publishedMeetingLink(item);
    final request = item.changeRequest;
    final info = <(String, String)>[
      (
        'Ngày họp / Tiết',
        '${scheduleDate(item.date)} · ${schedulePeriods(item.firstPeriod, item.lastPeriod)}',
      ),
      ('Hình thức', scheduleModality(item.modality)),
      (
        item.modality == 'ONLINE'
            ? (item.published ? 'Link họp' : 'Link dự kiến')
            : 'Phòng họp',
        scheduleLocation(item),
      ),
      ('Trạng thái chốt', scheduleConfirmation(item)),
      ('Trạng thái phòng', scheduleRoomState(item.roomState)),
      if (_detail) ...[
        ('Mã lớp', item.classCode),
        ('Mã GVCN', item.teacherCode),
        ('Hạn GVCN chốt lịch (giờ Việt Nam)', vietnamDateTime(item.deadline)),
        if (item.confirmedAt != null)
          (
            'Đã xác nhận lúc (giờ Việt Nam)',
            vietnamDateTime(item.confirmedAt!),
          ),
      ],
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: item.published
                      ? colors.primaryContainer
                      : colors.tertiaryContainer,
                ),
                child: Text(
                  item.published
                      ? 'Lịch đã công bố'
                      : 'Nguyện vọng chưa công bố',
                  style: TextStyle(
                    color: item.published
                        ? colors.onPrimaryContainer
                        : colors.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.roundName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lớp ${item.className ?? item.classCode} · '
              'Học kỳ ${item.semester} · Lần ${item.meetingNumber}',
            ),
            const SizedBox(height: 16),
            for (final (label, value) in info)
              _Info(label: label, value: value, selectable: _detail),
            if (!item.published)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Thông tin này là nguyện vọng của lớp, '
                  'chưa phải lịch đã công bố.',
                ),
              ),
            if (_detail && link != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('schedule-copy-link'),
                  onPressed: () => _copyLink(context, link),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Sao chép link họp'),
                ),
              ),
            const Divider(),
            Text(
              scheduleChangeState(item),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_detail && request != null) ...[
              const SizedBox(height: 12),
              _Info(
                label: 'Ngày / tiết đề nghị',
                value:
                    '${scheduleDate(request.date)} · ${schedulePeriods(request.firstPeriod, request.lastPeriod)}',
              ),
              _Info(
                label: 'Hình thức đề nghị',
                value: scheduleModality(request.modality),
              ),
              if (request.meetingLink != null)
                _Info(
                  label: 'Link đề nghị',
                  value:
                      safeMeetingLink(request.meetingLink) ??
                      'Link đề nghị chưa hợp lệ',
                ),
              _Info(label: 'Lý do đề nghị', value: request.reason),
              _Info(
                label: 'Ngày gửi (giờ Việt Nam)',
                value: vietnamDateTime(request.createdAt),
              ),
              if (request.processedAt != null)
                _Info(
                  label: 'Ngày xử lý (giờ Việt Nam)',
                  value: vietnamDateTime(request.processedAt!),
                ),
              if (request.result != null)
                _Info(label: 'Kết quả xử lý', value: request.result!),
            ],
            if (item.hasPendingChange)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Lịch hiện tại vẫn giữ nguyên trong khi chờ xử lý; '
                  'thời gian đề nghị chưa phải lịch có hiệu lực.',
                ),
              ),
            if (onOpen != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('schedule-${item.id}'),
                  onPressed: onOpen,
                  label: const Text('Xem chi tiết'),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
    this.selectable = true,
  });
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        if (selectable) SelectableText(value) else Text(value),
      ],
    ),
  );
}
