import 'package:flutter/material.dart';

import 'premium_health_ui.dart';

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FrostPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFC53A2E)),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Color(0xFFC53A2E)),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重新连接')),
          ],
        ),
      ),
    );
  }
}
