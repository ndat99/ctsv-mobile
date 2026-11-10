import 'package:flutter/material.dart';

class ScholarshipMessage extends StatelessWidget {
  const ScholarshipMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

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
