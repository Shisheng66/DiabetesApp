import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/premium_health_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _nutrition;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await ApiService.get('/dashboard/today');
      Map<String, dynamic>? nutrition;
      try {
        nutrition = await ApiService.get(
          '/diet/analysis/daily',
          query: {'date': today},
        );
      } catch (_) {
        nutrition = null;
      }
      if (!mounted) return;
      setState(() {
        _data = res;
        _nutrition = nutrition;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '首页加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  String _measureTypeText(String raw) {
    switch (raw) {
      case 'FASTING':
        return '空腹';
      case 'POST_MEAL':
        return '餐后';
      case 'BEFORE_SLEEP':
        return '睡前';
      case 'RANDOM':
        return '随机';
      default:
        return '暂无时段';
    }
  }

  String _measureTimeText(dynamic raw) {
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return DateFormat('HH:mm').format(dt.toLocal());
      }
    }
    return '--:--';
  }

  String _glucoseStatus(double? value) {
    if (value == null) return '等待第一条数据';
    if (value < 3.9) return '偏低，建议尽快补充碳水';
    if (value > 7.8) return '偏高，建议关注饮食与活动';
    return '状态平稳，继续保持';
  }

  Color _glucoseTone(double? value) {
    if (value == null) return const Color(0xFF55706D);
    if (value < 3.9) return const Color(0xFFE08A22);
    if (value > 7.8) return const Color(0xFFC53A2E);
    return const Color(0xFF0B8A7D);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _data?['latestGlucose'] as Map?;
    final glucose = _toDouble(latest?['valueMmolL']);
    final eat = _toDouble(_data?['todayTotalCalorieEaten']) ?? 0;
    final burn = _toDouble(_data?['todayTotalCalorieBurned']) ?? 0;
    final reminders = (_data?['reminders'] as List?) ?? const [];
    final tone = _glucoseTone(glucose);

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: HealthPageBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: FrostPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 42,
                        color: Color(0xFFC53A2E),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFC53A2E)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('重新连接')),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    _hero(glucose, eat, burn, tone),
                    const SizedBox(height: 14),
                    _focusStrip(glucose, latest, tone),
                    const SizedBox(height: 14),
                    _nutritionCaretakerCard(),
                    const SizedBox(height: 14),
                    _rhythmSection(eat, burn),
                    const SizedBox(height: 14),
                    _reminderSection(reminders),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _hero(double? glucose, double eat, double burn, Color tone) {
    final ratio = eat <= 0 ? 0.0 : (burn / eat).clamp(0.0, 1.2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A887B), Color(0xFF36A897), Color(0xFF6AC7B3)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280B8A7D),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            '把今天的血糖、饮食和活动\n收拢成一条清晰节奏线',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HeroMetric(
                  label: '最新血糖',
                  value: glucose == null
                      ? '--'
                      : '${glucose.toStringAsFixed(1)} mmol/L',
                ),
              ),
              Expanded(
                child: HeroMetric(
                  label: '摄入',
                  value: '${eat.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: HeroMetric(
                  label: '消耗',
                  value: '${burn.toStringAsFixed(0)} kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(
                tone == const Color(0xFFC53A2E)
                    ? const Color(0xFFFFD6CD)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _glucoseStatus(glucose),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusStrip(double? glucose, Map? latest, Color tone) {
    final type = _measureTypeText((latest?['measureType'] ?? '').toString());
    final measureTime = _measureTimeText(latest?['measureTime']);
    final value = glucose == null ? '--' : glucose.toStringAsFixed(1);
    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '今日焦点', subtitle: '把最关键的一组状态放在第一眼可读的位置'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: tone.withValues(alpha: 0.10),
                    border: Border.all(color: tone.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value mmol/L',
                        style: TextStyle(
                          color: tone,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '测量时间：$measureTime',
                        style: const TextStyle(
                          color: Color(0xFF35514E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前时段：$type',
                        style: const TextStyle(
                          color: Color(0xFF5A7673),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  children: const [
                    SoftStatPill(text: '空腹/餐后/睡前'),
                    SizedBox(height: 8),
                    SoftStatPill(
                      text: '提醒与记录联动',
                      bg: Color(0xFFFFF1E8),
                      fg: Color(0xFF7A4C2C),
                    ),
                    SizedBox(height: 8),
                    SoftStatPill(
                      text: '更聚焦的今日概览',
                      bg: Color(0xFFE7EEFF),
                      fg: Color(0xFF284C7C),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rhythmSection(double eat, double burn) {
    final net = eat - burn;
    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '今日节奏', subtitle: '把饮食与运动放到同一条能量轴线上观察'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statBlock(
                  '饮食摄入',
                  '${eat.toStringAsFixed(0)} kcal',
                  const Color(0xFFFFF1E8),
                  const Color(0xFF7A4C2C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBlock(
                  '运动消耗',
                  '${burn.toStringAsFixed(0)} kcal',
                  const Color(0xFFEAF6F2),
                  const Color(0xFF1D5B56),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _statBlock(
            net >= 0 ? '净剩余能量' : '净消耗能量',
            '${net.abs().toStringAsFixed(0)} kcal',
            const Color(0xFFE8EEFF),
            const Color(0xFF284C7C),
            full: true,
          ),
        ],
      ),
    );
  }

  Widget _nutritionCaretakerCard() {
    final nutrition = _nutrition;
    if (nutrition == null) {
      return FrostPanel(
        tint: const Color(0xFFFFF7EE),
        child: Row(
          children: const [
            Icon(Icons.restaurant_rounded, color: Color(0xFF9A6338)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '记录今天的饮食后，营养管家会自动给出下一餐建议。',
                style: TextStyle(
                  color: Color(0xFF6C4A2F),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final score = (_toDouble(nutrition['score']) ?? 0).round();
    final grade = '${nutrition['grade'] ?? '待评估'}';
    final headline = '${nutrition['headline'] ?? '营养管家已生成今日建议'}';
    final advice = '${nutrition['nextMealAdvice'] ?? ''}';
    final actions = _asList(nutrition['actionItems']);
    final risks = _asList(nutrition['riskFlags']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17312D), Color(0xFF0B756C), Color(0xFFFFD9AC)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2217332F),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '营养管家 · $grade',
                      style: const TextStyle(
                        color: Color(0xFFFFE8C8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (risks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: risks
                  .take(3)
                  .map(
                    (risk) => SoftStatPill(
                      text: '$risk',
                      bg: const Color(0xFFFFF1D7),
                      fg: const Color(0xFF6B3F13),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              advice,
              style: const TextStyle(
                color: Colors.white,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFFFFE8C8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${actions.first}',
                    style: const TextStyle(
                      color: Color(0xEFFFFFFF),
                      height: 1.32,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBlock(
    String label,
    String value,
    Color bg,
    Color fg, {
    bool full = false,
  }) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: fg.withValues(alpha: 0.82))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderSection(List reminders) {
    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '今日提醒', subtitle: '让记录、进餐和复测保持连续，不漏掉关键时间点'),
          const SizedBox(height: 14),
          if (reminders.isEmpty)
            const Text(
              '当前没有提醒，建议设置空腹、餐后和睡前提醒。',
              style: TextStyle(color: Color(0xFF5A7673)),
            )
          else
            ...reminders
                .take(6)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0B8A7D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$item',
                            style: const TextStyle(
                              height: 1.35,
                              color: Color(0xFF214240),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
