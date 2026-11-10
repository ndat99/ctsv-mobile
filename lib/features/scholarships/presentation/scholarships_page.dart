import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class ScholarshipsPage extends StatelessWidget {
  const ScholarshipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      key: Key('scholarships-page'),
      title: 'Học bổng tài trợ',
      icon: Icons.workspace_premium_outlined,
    );
  }
}
