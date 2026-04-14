import 'package:flutter/material.dart';

import '../widgets/premium_health_ui.dart';

/// 社区模块 — 后端接口尚未实现，暂时显示"功能开发中"占位界面。
/// 当后端 /api/community/posts 就绪后，删除此占位并恢复完整实现。
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社区')),
      body: HealthPageBackground(
        topTint: const Color(0xFFDCEFFC),
        bottomTint: const Color(0xFFF6F8FB),
        accent: const Color(0xFFFFE8D8),
        child: Center(
          child: FrostPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      size: 36,
                      color: Color(0xFF4677C8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '病友社区',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173836),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '社区功能正在开发中，即将上线。\n届时你可以分享控糖经验、交流饮食和运动心得。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF5A7673),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      SoftStatPill(text: '经验分享'),
                      SoftStatPill(
                        text: '饮食交流',
                        bg: Color(0xFFFFF1E8),
                        fg: Color(0xFF7A4C2C),
                      ),
                      SoftStatPill(
                        text: '运动互助',
                        bg: Color(0xFFEAF1FF),
                        fg: Color(0xFF355EA0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
