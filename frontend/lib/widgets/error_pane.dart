import 'package:flutter/material.dart';

import '../utils/display_text.dart';

class ErrorPane extends StatelessWidget {
  const ErrorPane({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFC53A2E),
          ),
          const SizedBox(height: 10),
          Text(
            DisplayText.userError(message),
            style: const TextStyle(color: Color(0xFFC53A2E)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
