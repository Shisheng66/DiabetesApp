import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _initialTabKey = 'initial_tab_index';

  int _index = 0;

  /// Tracks which pages have been visited so we can lazily build them.
  final Map<int, bool> _visited = {0: true};

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
  void initState() {
    super.initState();
    _restoreInitialTab();
  }

  Future<void> _restoreInitialTab() async {
    final prefs = await SharedPreferences.getInstance();
    final initialIndex = prefs.getInt(_initialTabKey);
    if (initialIndex == null) return;

    await prefs.remove(_initialTabKey);
    if (!mounted || initialIndex < 0 || initialIndex >= _pages.length) return;
    _visited[initialIndex] = true;
    setState(() => _index = initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final navBlur = kIsWeb
        ? 28.0
        : (defaultTargetPlatform == TargetPlatform.android ? 14.0 : 28.0);
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final useDesktopShell =
        wide &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (useDesktopShell) {
      return _DesktopMainShell(
        index: _index,
        pages: _pages,
        items: _items,
        visited: _visited,
        onSelect: (index) {
          _visited[index] = true;
          setState(() => _index = index);
        },
      );
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: List.generate(_pages.length, (i) {
          // Lazily build pages on first visit, keep alive with Offstage.
          if (!_visited.containsKey(i)) {
            return const SizedBox.shrink();
          }
          return Offstage(
            offstage: i != _index,
            child: _pages[i],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: navBlur, sigmaY: navBlur),
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
                        onTap: () {
                          _visited[i] = true;
                          setState(() => _index = i);
                        },
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

class _DesktopMainShell extends StatelessWidget {
  const _DesktopMainShell({
    required this.index,
    required this.pages,
    required this.items,
    required this.visited,
    required this.onSelect,
  });

  final int index;
  final List<Widget> pages;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  final Map<int, bool> visited;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final current = items[index];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE1F2EE), Color(0xFFF7FAF8), Color(0xFFFFE7D4)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                _DesktopSidebar(items: items, index: index, onSelect: onSelect),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopTopBar(title: current.label),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.48),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 30,
                                      offset: Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: List.generate(pages.length, (i) {
                                    if (!visited.containsKey(i)) {
                                      return const SizedBox.shrink();
                                    }
                                    return Offstage(
                                      offstage: i != index,
                                      child: pages[i],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B8A7D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Color(0xFF0B8A7D),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF173836),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} · 健康管家工作台',
                    style: const TextStyle(
                      color: Color(0xFF6B817E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SoftBadge(text: 'Web 预览版'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final List<({IconData icon, IconData activeIcon, String label})> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 214,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B8A7D), Color(0xFF76C7B8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '糖尿病\n健康管家',
                      style: TextStyle(
                        color: Color(0xFF173836),
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...List.generate(items.length, (i) {
                final item = items[i];
                final active = i == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DesktopNavItem(
                    label: item.label,
                    icon: active ? item.activeIcon : item.icon,
                    active: active,
                    onTap: () => onSelect(i),
                  ),
                );
              }),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  '提示：Web 端更适合快速查看趋势、报告和营养建议。',
                  style: TextStyle(
                    color: Color(0xFF7A4C2C),
                    height: 1.35,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: active
                ? Colors.white.withValues(alpha: 0.72)
                : Colors.transparent,
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active
                    ? const Color(0xFF0B8A7D)
                    : const Color(0xFF55706D),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF173836)
                      : const Color(0xFF55706D),
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoftBadge extends StatelessWidget {
  const SoftBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1F5E59),
          fontSize: 12,
          fontWeight: FontWeight.w900,
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
