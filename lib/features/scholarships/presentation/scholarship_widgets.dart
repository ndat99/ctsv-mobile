import 'package:flutter/material.dart';

class ScholarshipAcceptance extends StatelessWidget {
  const ScholarshipAcceptance({super.key, required this.accepting});

  final bool accepting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accepting
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        accepting ? 'Đang nhận hồ sơ' : 'Không nhận hồ sơ',
        style: TextStyle(
          color: accepting
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
