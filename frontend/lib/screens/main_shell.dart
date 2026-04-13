import 'dart:ui';

import 'package:flutter/material.dart';

import 'community_screen.dart';
import 'diet_screen.dart';
import 'exercise_screen.dart';
import 'glucose_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    GlucoseScreen(),
    DietScreen(),
    ExerciseScreen(),
    ReportScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  final _items = const <({IconData icon, IconData activeIcon, String label})>[
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '首页'),
    (
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart,
      label: '血糖',
    ),
    (
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu,
      label: '饮食',
    ),
    (
      icon: Icons.directions_run_outlined,
      activeIcon: Icons.directions_run,
      label: '运动',
    ),
    (
      icon: Icons.query_stats_outlined,
      activeIcon: Icons.query_stats,
      label: '报告',
    ),
    (icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: '社区'),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final active = i == _index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: _NavItem(
                        label: item.label,
                        icon: active ? item.activeIcon : item.icon,
                        active: active,
                        onTap: () => setState(() => _index = i),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0B8A7D);
    const inactiveColor = Color(0xFF55706D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            border: active
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 0.7,
                  )
                : null,
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x0B000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? activeColor.withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
