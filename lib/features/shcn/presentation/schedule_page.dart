import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      key: Key('schedule-page'),
      title: 'Lịch sinh hoạt chủ nhiệm',
      icon: Icons.calendar_month_outlined,
    );
  }
}
