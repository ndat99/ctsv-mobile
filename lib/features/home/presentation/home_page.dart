import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenSchedules,
    required this.onOpenScholarships,
  });

  final VoidCallback onOpenSchedules;
  final VoidCallback onOpenScholarships;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const Key('home-page'),
      padding: const EdgeInsets.all(24),
      children: [
        Text('Công tác sinh viên', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Đại học Bách khoa · Đại học Đà Nẵng',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        _FeatureCard(
          icon: Icons.calendar_month_outlined,
          title: 'Lịch sinh hoạt chủ nhiệm',
          subtitle: 'Theo dõi lịch sinh hoạt của lớp.',
          onTap: onOpenSchedules,
        ),
        const SizedBox(height: 16),
        _FeatureCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Học bổng tài trợ',
          subtitle: 'Tra cứu thông báo và cơ hội học bổng.',
          onTap: onOpenScholarships,
        ),
        const SizedBox(height: 32),
        Text('Tiện ích khác', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: null, child: Text('Điểm rèn luyện')),
            OutlinedButton(onPressed: null, child: Text('Miễn giảm học phí')),
            OutlinedButton(onPressed: null, child: Text('Học bổng KKHT')),
            OutlinedButton(onPressed: null, child: Text('Học bổng du học')),
            OutlinedButton(onPressed: null, child: Text('Hồ sơ ký số')),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
