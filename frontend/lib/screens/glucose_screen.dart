import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/glucose_stats_widgets.dart';
import '../widgets/premium_health_ui.dart';

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key});

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  static const _labels = <String, String>{
    'ALL': '全部',
    'FASTING': '空腹',
    'POST_MEAL': '餐后',
    'BEFORE_SLEEP': '睡前',
    'RANDOM': '随机',
  };

  DateTime _date = DateTime.now();
  String _range = 'WEEK';
  String _typeFilter = 'ALL';
  bool _loading = true;
  bool _trendLoading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _trend = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([_loadRecords(), _loadTrend(), _loadProfile()]);
      if (!mounted) return;
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _loadRecords() async {
    final day = DateFormat('yyyy-MM-dd').format(_date);
    final res = await ApiService.get(
      '/blood-glucose/records',
      query: {'startDate': day, 'endDate': day, 'page': '0', 'size': '120'},
    );
    final list = _extractList(res).map(_asMap).toList();
    list.sort(
      (a, b) => _toDate(b['measureTime']).compareTo(_toDate(a['measureTime'])),
    );
    _records = list;
  }

  Future<void> _loadTrend() async {
    setState(() => _trendLoading = true);
    try {
      Map<String, dynamic> res;
      if (_range == 'WEEK') {
        final weekStart = _date.subtract(Duration(days: _date.weekday - 1));
        res = await ApiService.get(
          '/blood-glucose/trend/weekly',
          query: {'weekStart': DateFormat('yyyy-MM-dd').format(weekStart)},
        );
      } else {
        res = await ApiService.get(
          '/blood-glucose/trend/monthly',
          query: {'year': '${_date.year}', 'month': '${_date.month}'},
        );
      }
      _trend = ((res['points'] as List?) ?? const []).map(_asMap).toList();
    } finally {
      if (mounted) setState(() => _trendLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await ApiService.get('/users/me/health-profile');
    } catch (_) {
      _profile = null;
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> res) {
    if (res['content'] is List) return res['content'] as List;
    if (res['data'] is List) return res['data'] as List;
    final data = res['data'];
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return const <String, dynamic>{};
  }

  double? _toDouble(dynamic v) {
    final parsed = v is num ? v.toDouble() : double.tryParse('$v');
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  DateTime _toDate(dynamic v) {
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double get _targetMin => (_toDouble(_profile?['targetFbgMin']) ?? 3.9) <= 0
      ? 3.9
      : (_toDouble(_profile?['targetFbgMin']) ?? 3.9);
  double get _targetMax => (_toDouble(_profile?['targetFbgMax']) ?? 7.8) <= 0
      ? 7.8
      : (_toDouble(_profile?['targetFbgMax']) ?? 7.8);

  List<Map<String, dynamic>> get _rows => _typeFilter == 'ALL'
      ? _records
      : _records.where((e) => '${e['measureType']}' == _typeFilter).toList();

  ({
    int count,
    int normal,
    int low,
    int high,
    double? avg,
    double? min,
    double? max,
  })
  get _stats {
    final values = _records
        .map((e) => _toDouble(e['valueMmolL']))
        .whereType<double>()
        .toList();
    if (values.isEmpty) {
      return (
        count: 0,
        normal: 0,
        low: 0,
        high: 0,
        avg: null,
        min: null,
        max: null,
      );
    }
    var normal = 0;
    var low = 0;
    var high = 0;
    for (final v in values) {
      if (v < _targetMin) {
        low++;
      } else if (v > _targetMax) {
        high++;
      } else {
        normal++;
      }
    }
    return (
      count: values.length,
      normal: normal,
      low: low,
      high: high,
      avg: values.reduce((a, b) => a + b) / values.length,
      min: values.reduce(min),
      max: values.reduce(max),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _loadAll();
  }

  Future<void> _addRecord([String defaultType = 'FASTING']) async {
    final valueCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    var type = defaultType;
    var measuredTime = TimeOfDay.fromDateTime(DateTime.now());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '记录每日血糖',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: '测量时段'),
                  items: const [
                    DropdownMenuItem(value: 'FASTING', child: Text('空腹')),
                    DropdownMenuItem(value: 'POST_MEAL', child: Text('餐后')),
                    DropdownMenuItem(value: 'BEFORE_SLEEP', child: Text('睡前')),
                    DropdownMenuItem(value: 'RANDOM', child: Text('随机')),
                  ],
                  onChanged: (v) => setModal(() => type = v ?? type),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: measuredTime,
                    );
                    if (picked == null) return;
                    setModal(() => measuredTime = picked);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '测量时间'),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: Color(0xFF0B8A7D),
                        ),
                        const SizedBox(width: 8),
                        Text(measuredTime.format(ctx)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '血糖值 (mmol/L)',
                    hintText: '例如 6.1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: remarkCtrl,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    final value = double.tryParse(valueCtrl.text.trim());
                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(const SnackBar(content: Text('请输入有效血糖值')));
                      return;
                    }
                    try {
                      final local = DateTime(
                        _date.year,
                        _date.month,
                        _date.day,
                        measuredTime.hour,
                        measuredTime.minute,
                      );
                      await ApiService.post('/blood-glucose/records', {
                        'measureTime': local.toUtc().toIso8601String(),
                        'measureType': type,
                        'valueMmolL': value,
                        'source': 'MANUAL',
                        'remark': remarkCtrl.text.trim().isEmpty
                            ? null
                            : remarkCtrl.text.trim(),
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      await _loadAll();
                      if (!mounted) return;
                      AppToast.success(context, '血糖记录添加成功');
                    } on ApiException catch (e) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text('保存记录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(dynamic id) async {
    if (id == null) return;
    try {
      await ApiService.delete('/blood-glucose/records/$id');
      await _loadAll();
      if (!mounted) return;
      AppToast.success(context, '血糖记录删除成功');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _bucket(DateTime dt) {
    final h = dt.hour;
    if (h >= 5 && h < 11) return '上午';
    if (h >= 11 && h < 15) return '中午';
    if (h >= 15 && h < 19) return '下午';
    return '晚间';
  }

  Color _valueColor(double v) => v < _targetMin
      ? const Color(0xFFE08A22)
      : (v > _targetMax ? const Color(0xFFC53A2E) : const Color(0xFF0B8A7D));
  String _status(double v) =>
      v < _targetMin ? '偏低' : (v > _targetMax ? '偏高' : '正常');

  Widget _summaryCard() {
    final s = _stats;
    final rate = s.count == 0 ? 0 : (s.normal / s.count * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B8A7D), Color(0xFF2CA392), Color(0xFF70C5B3)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B8A7D),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy-MM-dd').format(_date),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _pickDate,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('切换日期'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '把血糖波动拆成一条可读的时间线',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('次数', '${s.count}'),
              _metric('均值', s.avg?.toStringAsFixed(1) ?? '--'),
              _metric('最低', s.min?.toStringAsFixed(1) ?? '--'),
              _metric('最高', s.max?.toStringAsFixed(1) ?? '--'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                '目标 ${_targetMin.toStringAsFixed(1)}-${_targetMax.toStringAsFixed(1)}',
              ),
              _chip('达标率 $rate%'),
              _chip('偏低 ${s.low}'),
              _chip('偏高 ${s.high}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _adviceCard() {
    final s = _stats;
    final tips = <String>[];
    var title = '今日血糖总体平稳';
    var color = const Color(0xFF0B8A7D);
    if (_records.isNotEmpty) {
      final latest = _toDouble(_records.first['valueMmolL']) ?? 0;
      if (latest > _targetMax) {
        title = '出现偏高血糖，请关注';
        color = const Color(0xFFC53A2E);
        tips.add('减少下一餐精制碳水，优先蔬菜和优质蛋白。');
        tips.add('餐后步行 20-30 分钟帮助回落。');
      } else if (latest < _targetMin) {
        title = '出现偏低血糖，请及时处理';
        color = const Color(0xFFE08A22);
        tips.add('先补充 15g 快速碳水，15 分钟后复测。');
      }
    }
    if (s.high >= 2) tips.add('今日偏高次数较多，建议晚餐主食减量。');
    if (s.low >= 2) tips.add('今日偏低次数较多，建议复核药量和进餐间隔。');
    if (tips.isEmpty) tips.add('继续保持规律监测，重点关注空腹和餐后数据。');

    return FrostPanel(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: '智能建议',
              subtitle: '根据当天记录，快速给出下一步更适合的饮食和活动动作',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...tips
                .take(3)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t, style: const TextStyle(height: 1.32)),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _trendCard() {
    return FrostPanel(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: '血糖趋势',
              subtitle: '观察近一周或近一月的整体波动方向',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('周'),
                    selected: _range == 'WEEK',
                    onSelected: (_) async {
                      setState(() => _range = 'WEEK');
                      await _loadTrend();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('月'),
                    selected: _range == 'MONTH',
                    onSelected: (_) async {
                      setState(() => _range = 'MONTH');
                      await _loadTrend();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_trendLoading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_trend.isEmpty)
              const SizedBox(height: 160, child: Center(child: Text('暂无趋势数据')))
            else ...[
              SizedBox(height: 220, child: _lineChart()),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(const Color(0xFF0B8A7D)),
                  const SizedBox(width: 4),
                  const Text(
                    '血糖值',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A7673)),
                  ),
                  const SizedBox(width: 16),
                  _legendDash(const Color(0xFFE08A22)),
                  const SizedBox(width: 4),
                  const Text(
                    '目标下限',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A7673)),
                  ),
                  const SizedBox(width: 16),
                  _legendDash(const Color(0xFFC53A2E)),
                  const SizedBox(width: 4),
                  const Text(
                    '目标上限',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A7673)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineChart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _trend.length; i++) {
      final value = _toDouble(_trend[i]['value']);
      if (value == null) continue;
      spots.add(FlSpot(i.toDouble(), value));
    }
    if (spots.length < 2) {
      return const Center(child: Text('数据不足，至少需要 2 条趋势数据'));
    }

    final ys = spots.map((e) => e.y).toList();
    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);
    final pad = max(0.8, (maxY - minY) * 0.2);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - pad,
        maxY: maxY + pad,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _targetMin,
              color: const Color(0xFFE08A22),
              strokeWidth: 1.2,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                style: const TextStyle(
                  color: Color(0xFFE08A22),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (line) => '目标下限 ${line.y.toStringAsFixed(1)}',
              ),
            ),
            HorizontalLine(
              y: _targetMax,
              color: const Color(0xFFC53A2E),
              strokeWidth: 1.2,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                style: const TextStyle(
                  color: Color(0xFFC53A2E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (line) => '目标上限 ${line.y.toStringAsFixed(1)}',
              ),
            ),
          ],
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _trend.length <= 2 ? 1 : ((_trend.length - 1) / 2),
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= _trend.length) return const SizedBox.shrink();
                final raw = '${_trend[i]['time'] ?? ''}';
                final label = raw.length > 5
                    ? raw.substring(raw.length - 5)
                    : raw;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: const Color(0xFF0B8A7D),
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B8A7D).withValues(alpha: 0.24),
                  const Color(0xFF0B8A7D).withValues(alpha: 0.03),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard() {
    final rows = _rows;
    if (rows.isEmpty) return _emptyCard();
    final grouped = <String, List<Map<String, dynamic>>>{
      '上午': [],
      '中午': [],
      '下午': [],
      '晚间': [],
    };
    for (final r in rows) {
      grouped[_bucket(_toDate(r['measureTime']))]!.add(r);
    }

    return FrostPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: '分时段时间轴',
              subtitle: '把每一条记录放回具体时段和测量时间里查看',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _showAbnormalHistory,
                    child: const Text('异常记录'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: _addRecord,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('新增'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _labels.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _typeFilter == e.key,
                          onSelected: (_) =>
                              setState(() => _typeFilter = e.key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            ...grouped.entries
                .where((e) => e.value.isNotEmpty)
                .map((g) => _timelineGroup(g.key, g.value)),
          ],
        ),
      ),
    );
  }

  Widget _timelineGroup(String title, List<Map<String, dynamic>> list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title · ${list.length} 条',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF285E59),
            ),
          ),
          const SizedBox(height: 8),
          ...list.asMap().entries.map(
            (e) => _timelineItem(e.value, e.key == list.length - 1),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(Map<String, dynamic> item, bool isLast) {
    final v = _toDouble(item['valueMmolL']) ?? 0;
    final color = _valueColor(v);
    final type = _labels['${item['measureType']}'] ?? '${item['measureType']}';
    final remark = '${item['remark'] ?? ''}'.trim();
    final timeLabel = DateFormat('HH:mm').format(_toDate(item['measureTime']));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Container(width: 2, height: 56, color: const Color(0xFFD2E6E2)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE8E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${v.toStringAsFixed(1)} mmol/L',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _pill(_status(v), color),
                    const Spacer(),
                    Text(
                      timeLabel,
                      style: const TextStyle(color: Color(0xFF5A7673)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _pill('$type · $timeLabel', const Color(0xFF0B8A7D)),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => _deleteRecord(item['id']),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
                if (remark.isNotEmpty)
                  Text(
                    '备注：$remark',
                    style: const TextStyle(color: Color(0xFF5A7673)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  Widget _emptyCard() {
    return FrostPanel(
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            Positioned(
              top: 24,
              left: 18,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDE9E2).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4D0).withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF8F5), Color(0xFFD6F0EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 24,
                          offset: Offset(0, 8),
                          color: Color(0x1F0B8A7D),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_heart_rounded,
                          size: 40,
                          color: Color(0xFF0B8A7D),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B8A7D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '今天还没有血糖记录',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '先记录一条数据，时间轴和建议会自动生成',
                    style: TextStyle(color: Color(0xFF5A7673)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addRecord,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('记录第一条'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日血糖'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: GlassActionButton(
          onTap: _addRecord,
          icon: Icons.add_rounded,
          label: '记录血糖',
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(),
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: HealthPageBackground(
            topTint: const Color(0xFFD9F1EE),
            accent: const Color(0xFFFFEADB),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 10),
                ],
                if (_error != null) ...[
                  FrostPanel(
                    tint: const Color(0xFFFFF4F1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: Color(0xFFC53A2E),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '数据加载失败',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC53A2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFF8F3B32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonal(
                                onPressed: _loadAll,
                                child: const Text('重新连接'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _summaryCard(),
                const SizedBox(height: 12),
                FrostPanel(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _quickBtn(
                        '空腹',
                        Icons.wb_sunny_outlined,
                        () => _addRecord('FASTING'),
                      ),
                      _quickBtn(
                        '餐后',
                        Icons.restaurant_outlined,
                        () => _addRecord('POST_MEAL'),
                      ),
                      _quickBtn(
                        '睡前',
                        Icons.nightlight_outlined,
                        () => _addRecord('BEFORE_SLEEP'),
                      ),
                      _quickBtn(
                        '随机',
                        Icons.schedule_rounded,
                        () => _addRecord('RANDOM'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _adviceCard(),
                if (_records.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TirCard(
                    values: _records
                        .map((r) => _toDouble(r['valueMmolL']) ?? 0.0)
                        .where((v) => v > 0)
                        .toList(),
                    targetMin: _targetMin,
                    targetMax: _targetMax,
                  ),
                ],
                const SizedBox(height: 12),
                _trendCard(),
                if (_stats.avg != null) ...[
                  const SizedBox(height: 12),
                  HbA1cBanner(avgGlucose: _stats.avg!),
                ],
                const SizedBox(height: 12),
                _timelineCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickBtn(String t, IconData i, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Ink(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(i, color: const Color(0xFF0B8A7D)),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _legendDash(Color color) => Container(
    width: 18,
    height: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );

  Future<void> _showAbnormalHistory() async {
    try {
      final res = await ApiService.get(
        '/blood-glucose/abnormal-events',
        query: {'page': '0', 'size': '50'},
      );
      final list = ((res['content'] ?? res['data']) as List? ?? const [])
          .map((e) => e is Map<String, dynamic>
              ? e
              : (e is Map ? e.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{}))
          .toList();

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          if (list.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('近期无异常血糖记录')),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final isHigh = item['type'] == 'HIGH';
              final color = isHigh
                  ? const Color(0xFFC53A2E)
                  : const Color(0xFFE08A22);
              final label = isHigh ? '偏高' : '偏低';
              final timeStr = item['createdAt'] is String
                  ? DateFormat('MM-dd HH:mm')
                      .format(DateTime.parse(item['createdAt']).toLocal())
                  : '--';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text('血糖$label事件'),
                subtitle: Text(timeStr),
                trailing: item['handled'] == true
                    ? const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF0B8A7D),
                      )
                    : const Icon(
                        Icons.pending_outlined,
                        color: Color(0xFF9AA8A6),
                      ),
              );
            },
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
