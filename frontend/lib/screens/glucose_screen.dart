import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/display_text.dart';
import '../utils/json_helpers.dart';
import '../widgets/app_toast.dart';
import '../widgets/glucose_rhythm_painter.dart';

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
  String _typeFilter = 'ALL';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (!mounted) return;
    setState(() {
      if (showLoading) {
        _loading = true;
      }
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _fetchRecords().timeout(const Duration(seconds: 12)),
        _fetchProfile().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _records = results[0] as List<Map<String, dynamic>>;
        _profile = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '连接服务超时，请稍后重试';
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

  Future<List<Map<String, dynamic>>> _fetchRecords() async {
    final day = DateFormat('yyyy-MM-dd').format(_date);
    final res = await ApiService.get(
      '/blood-glucose/records',
      query: {'startDate': day, 'endDate': day, 'page': '0', 'size': '200'},
    );
    final list = extractList(res).map(asMap).toList();
    list.sort(
      (a, b) => _toDate(b['measureTime']).compareTo(_toDate(a['measureTime'])),
    );
    return list;
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    try {
      return await ApiService.get('/users/me/health-profile');
    } catch (_) {
      return null;
    }
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
    await _loadAll();
  }

  Future<void> _addRecord([String defaultType = 'FASTING']) async {
    final valueCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    var type = defaultType;
    var measuredTime = TimeOfDay.fromDateTime(DateTime.now());
    var submitting = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> submit() async {
              if (submitting) return;
              final value = double.tryParse(valueCtrl.text.trim());
              if (value == null || value <= 0 || value > 35) {
                AppToast.info(context, '请输入合理的血糖值');
                return;
              }
              setModal(() => submitting = true);
              final localTime = DateTime(
                _date.year,
                _date.month,
                _date.day,
                measuredTime.hour,
                measuredTime.minute,
              );
              try {
                await ApiService.post('/blood-glucose/records', {
                  'measureType': type,
                  'measureTime': localTime.toUtc().toIso8601String(),
                  'valueMmolL': value,
                  'source': 'MANUAL',
                  'remark': remarkCtrl.text.trim().isEmpty
                      ? null
                      : remarkCtrl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(true);
              } on ApiException catch (e) {
                if (!mounted) return;
                AppToast.info(context, e.message);
                if (ctx.mounted) {
                  setModal(() => submitting = false);
                }
              } catch (_) {
                if (!mounted) return;
                AppToast.info(context, '添加失败，请稍后重试');
                if (ctx.mounted) {
                  setModal(() => submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '记录每日血糖',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF153C38),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: '测量时段'),
                      items: const [
                        DropdownMenuItem(value: 'FASTING', child: Text('空腹')),
                        DropdownMenuItem(value: 'POST_MEAL', child: Text('餐后')),
                        DropdownMenuItem(
                          value: 'BEFORE_SLEEP',
                          child: Text('睡前'),
                        ),
                        DropdownMenuItem(value: 'RANDOM', child: Text('随机')),
                      ],
                      onChanged: (value) =>
                          setModal(() => type = value ?? type),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '血糖值',
                        suffixText: 'mmol/L',
                        hintText: '例如 6.8',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: measuredTime,
                              );
                              if (picked != null && ctx.mounted) {
                                setModal(() => measuredTime = picked);
                              }
                            },
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text('测量时间：${measuredTime.format(ctx)}'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '可填写饮食、运动或身体状态',
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存记录'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      valueCtrl.dispose();
      remarkCtrl.dispose();
      return;
    }
    valueCtrl.dispose();
    remarkCtrl.dispose();

    if (saved == true) {
      AppToast.success(context, '血糖记录已添加');
      await _loadAll(showLoading: false);
    }
  }

  Future<void> _deleteRecord(dynamic id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条血糖记录吗？'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/blood-glucose/records/$id');
      if (!mounted) return;
      AppToast.success(context, '血糖记录已删除');
      await _loadAll(showLoading: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.info(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.info(context, '删除失败，请稍后重试');
    }
  }

  DateTime _toDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double get _targetMin {
    final value = toDouble(_profile?['targetFbgMin']) ?? 3.9;
    return value > 0 ? value : 3.9;
  }

  double get _targetMax {
    final value = toDouble(_profile?['targetFbgMax']) ?? 7.8;
    return value > 0 ? value : 7.8;
  }

  String _typeCode(dynamic value) {
    final label = DisplayText.glucoseMeasure(value);
    switch (label) {
      case '空腹':
        return 'FASTING';
      case '餐后':
        return 'POST_MEAL';
      case '睡前':
        return 'BEFORE_SLEEP';
      case '随机':
        return 'RANDOM';
      default:
        return '${value ?? ''}'.trim().toUpperCase().replaceAll('-', '_');
    }
  }

  List<Map<String, dynamic>> get _rows {
    if (_typeFilter == 'ALL') return _records;
    return _records
        .where((row) => _typeCode(row['measureType']) == _typeFilter)
        .toList();
  }

  List<Map<String, dynamic>> get _chronologicalRows {
    final rows = [..._rows];
    rows.sort(
      (a, b) => _toDate(a['measureTime']).compareTo(_toDate(b['measureTime'])),
    );
    return rows;
  }

  _GlucoseStats get _stats {
    final values = _records
        .map((e) => toDouble(e['valueMmolL']))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return const _GlucoseStats.empty();
    var low = 0;
    var normal = 0;
    var high = 0;
    for (final value in values) {
      if (value < _targetMin) {
        low++;
      } else if (value > _targetMax) {
        high++;
      } else {
        normal++;
      }
    }
    return _GlucoseStats(
      count: values.length,
      normal: normal,
      low: low,
      high: high,
      average: values.reduce((a, b) => a + b) / values.length,
      min: values.reduce(math.min),
      max: values.reduce(math.max),
    );
  }

  String _typeLabel(dynamic raw) => DisplayText.glucoseMeasure(raw);

  String _timeText(dynamic raw) {
    final date = _toDate(raw);
    if (date.millisecondsSinceEpoch == 0) return '--:--';
    return DateFormat('HH:mm').format(date);
  }

  Color _toneForValue(double? value) {
    if (value == null) return const Color(0xFF5E7470);
    if (value < _targetMin) return const Color(0xFFE08A22);
    if (value > _targetMax) return const Color(0xFFC53A2E);
    return const Color(0xFF0B8A7D);
  }

  String _statusForValue(double? value) {
    if (value == null) return '等待记录';
    if (value < _targetMin) return '偏低';
    if (value > _targetMax) return '偏高';
    return '达标';
  }

  String _smartAdvice() {
    final stats = _stats;
    if (stats.count == 0) {
      return '今天还没有血糖记录。建议先补一条空腹或餐后记录，后续建议会更准确。';
    }
    if (stats.high >= math.max(stats.normal, stats.low) && stats.high > 0) {
      return '今天偏高记录较多，下一餐建议控制主食分量，餐后安排 15-30 分钟轻度步行。';
    }
    if (stats.low > 0) {
      return '今天出现偏低记录，请留意是否漏餐或运动过量，外出时建议随身准备低血糖应急食物。';
    }
    return '今天血糖整体平稳。继续保持规律进餐、稳定碳水和适度活动。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3F0),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        padding: const EdgeInsets.only(bottom: 82),
        child: FloatingActionButton.extended(
          heroTag: 'glucose_add_record_fab_clean_v1',
          onPressed: () => _addRecord(),
          backgroundColor: const Color(0xFF0B8A7D),
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            '记录血糖',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDDF1EC), Color(0xFFF8FBF8), Color(0xFFFFF0E2)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _loading ? _loadingState() : _content(),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text('正在同步血糖数据', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 118),
            sliver: SliverList.list(
              children: [
                if (_error != null) ...[
                  _errorCard(),
                  const SizedBox(height: 12),
                ],
                _heroCard(),
                const SizedBox(height: 12),
                _filterCard(),
                const SizedBox(height: 12),
                _chartCard(),
                const SizedBox(height: 12),
                _timeMapCard(),
                const SizedBox(height: 12),
                _adviceCard(),
                const SizedBox(height: 12),
                _recordsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return _GlassCard(
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFC53A2E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFC53A2E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    final latest = _records.isEmpty ? null : _records.first;
    final latestValue = toDouble(latest?['valueMmolL']);
    final tone = _toneForValue(latestValue);
    final stats = _stats;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A6D64), Color(0xFF0B8A7D), Color(0xFF7DCEBE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B8A7D).withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(_date),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日血糖状态',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _smartAdvice(),
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.tir.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '达标率',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: '最新',
                  value: latestValue == null
                      ? '--'
                      : latestValue.toStringAsFixed(1),
                  unit: 'mmol/L',
                  accent: tone,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: '均值',
                  value: stats.average == null
                      ? '--'
                      : stats.average!.toStringAsFixed(1),
                  unit: 'mmol/L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: '记录',
                  value: '${stats.count}',
                  unit: '次',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '测量时段', subtitle: '切换后图表和列表会同步过滤'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labels.entries.map((entry) {
              final selected = _typeFilter == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => setState(() => _typeFilter = entry.key),
                selectedColor: const Color(0xFF0B8A7D),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF385450),
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFD8E8E4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    final rows = _chronologicalRows;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: '血糖节律图',
            subtitle: '新的图形表不接管手势，整页都能顺畅上下滑动',
          ),
          const SizedBox(height: 14),
          Container(
            height: 226,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FCFA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white),
            ),
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      '暂无记录，添加一条后这里会生成节律图',
                      style: TextStyle(color: Color(0xFF6B7D79)),
                    ),
                  )
                : CustomPaint(
                    painter: GlucoseRhythmPainter(
                      records: rows,
                      targetMin: _targetMin,
                      targetMax: _targetMax,
                      valueOf: (row) => toDouble(row['valueMmolL']),
                      timeOf: (row) => _timeText(row['measureTime']),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _timeMapCard() {
    final byType = <String, Map<String, dynamic>?>{};
    for (final key in ['FASTING', 'POST_MEAL', 'BEFORE_SLEEP', 'RANDOM']) {
      byType[key] = _records.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row != null && _typeCode(row['measureType']) == key,
        orElse: () => null,
      );
    }
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '分时段地图', subtitle: '空腹、餐后、睡前三个关键点一眼确认'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
            children: ['FASTING', 'POST_MEAL', 'BEFORE_SLEEP', 'RANDOM'].map((
              type,
            ) {
              final row = byType[type];
              final value = toDouble(row?['valueMmolL']);
              final tone = _toneForValue(value);
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _addRecord(type),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tone.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _typeLabel(type),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF173B37),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                            color: tone,
                          ),
                        ],
                      ),
                      Text(
                        value == null ? '--' : value.toStringAsFixed(1),
                        style: TextStyle(
                          color: tone,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        row == null
                            ? '点击补记'
                            : '${_statusForValue(value)} · ${_timeText(row['measureTime'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF607672),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _adviceCard() {
    final stats = _stats;
    return _GlassCard(
      tint: const Color(0xFFFFF8EF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE8CF),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF9A6338),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '智能建议',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173B37),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _smartAdvice(),
                  style: const TextStyle(
                    height: 1.42,
                    color: Color(0xFF526A66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SoftPill('偏高 ${stats.high}'),
                    _SoftPill('偏低 ${stats.low}'),
                    _SoftPill('达标 ${stats.normal}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordsCard() {
    final rows = _rows;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(title: '记录明细', subtitle: '按测量时间倒序展示'),
              ),
              TextButton.icon(
                onPressed: () => _addRecord(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('新增'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FCFA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 42,
                    color: Color(0xFF8CA19D),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '当前筛选下暂无记录',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF385450),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '点击右下角按钮添加一条血糖记录',
                    style: TextStyle(color: Color(0xFF6B7D79)),
                  ),
                ],
              ),
            )
          else
            ...rows.map(_recordTile),
        ],
      ),
    );
  }

  Widget _recordTile(Map<String, dynamic> row) {
    final value = toDouble(row['valueMmolL']);
    final tone = _toneForValue(value);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.monitor_heart_rounded, color: tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${value == null ? '--' : value.toStringAsFixed(1)} mmol/L',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_typeLabel(row['measureType'])} · ${_timeText(row['measureTime'])} · ${_statusForValue(value)}',
                  style: const TextStyle(
                    color: Color(0xFF526A66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ('${row['remark'] ?? ''}'.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${row['remark']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF7A8D89)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteRecord(row['id']),
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF9AA8A6),
          ),
        ],
      ),
    );
  }
}

class _GlucoseStats {
  const _GlucoseStats({
    required this.count,
    required this.normal,
    required this.low,
    required this.high,
    required this.average,
    required this.min,
    required this.max,
  });

  const _GlucoseStats.empty()
    : count = 0,
      normal = 0,
      low = 0,
      high = 0,
      average = null,
      min = null,
      max = null;

  final int count;
  final int normal;
  final int low;
  final int high;
  final double? average;
  final double? min;
  final double? max;

  double get tir => count == 0 ? 0 : normal * 100 / count;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F38).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF173B37),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7D79),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.unit,
    this.accent,
  });

  final String label;
  final String value;
  final String unit;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  const _SoftPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF526A66),
        ),
      ),
    );
  }
}
