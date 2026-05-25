import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class CaptchaRow extends StatelessWidget {
  const CaptchaRow({
    super.key,
    required this.controller,
    required this.imageDataUri,
    required this.loading,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final String? imageDataUri;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImageDataUri(imageDataUri);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: '请输入验证码'),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 118,
          height: 46,
          padding: const EdgeInsets.fromLTRB(10, 0, 2, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4F1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E8E4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: loading
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : imageBytes == null
                    ? const Center(
                        child: Text(
                          '点击刷新',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E4B43),
                          ),
                        ),
                      )
                    : Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: '刷新验证码',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Uint8List? _decodeImageDataUri(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final commaIndex = value.indexOf(',');
    final base64Part = commaIndex >= 0
        ? value.substring(commaIndex + 1)
        : value;
    try {
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }
}
