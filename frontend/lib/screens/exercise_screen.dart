import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/premium_health_ui.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<dynamic> _types = [];
  List<dynamic> _records = [];
  Map<String, dynamic>? _energyTip;
  String? _energyError;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return const {};
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  String _numText(dynamic value, {int fraction = 0}) {
    final v = _toDouble(value);
    if (v == null) return '0';
    if (fraction == 0) return v.round().toString();
    return v.toStringAsFixed(fraction);
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _energyError = null;
    });

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final typesRes = await ApiService.get('/exercise/types');
      final recordsRes = await ApiService.get(
        '/exercise/records',
        query: {'page': '0', 'size': '50'},
      );

      Map<String, dynamic>? energy;
      String? energyErr;
      try {
        energy = await ApiService.get(
          '/exercise/recommendation/daily',
          query: {'date': todayStr},
        );
      } on ApiException catch (e) {
        energyErr = e.message;
      } catch (_) {
        energyErr = '热量建议加载失败';
      }

      if (!mounted) return;
      setState(() {
        _types = _extractList(typesRes);
        _records = _extractList(recordsRes);
        _energyTip = energy;
        _energyError = energyErr;
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
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is List) return data;
    final content = res['content'];
    if (content is List) return content;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List;
    }
    return const [];
  }

  Future<void> _showAdd() async {
    if (_types.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未找到运动类型，请检查后端数据')));
      return;
    }

    int? typeId = _toInt(_asMap(_types.first)['id']);
    final durationCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '新增运动记录',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: typeId,
                      decoration: const InputDecoration(labelText: '运动类型'),
                      items: _types.map((raw) {
                        final item = _asMap(raw);
                        return DropdownMenuItem<int>(
                          value: _toInt(item['id']),
                          child: Text('${item['name'] ?? ''}'),
                        );
                      }).toList(),
                      onChanged: (value) => setModal(() => typeId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '时长（分钟）'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      decoration: const InputDecoration(labelText: '备注（可选）'),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final min =
                                  int.tryParse(durationCtrl.text.trim()) ?? 0;
                              if (typeId == null || min <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('请输入有效时长')),
                                );
                                return;
                              }

                              setModal(() => submitting = true);
                              try {
                                await ApiService.post('/exercise/records', {
                                  'exerciseTypeId': typeId,
                                  'startTime': DateTime.now()
                                      .toUtc()
                                      .toIso8601String(),
                                  'durationMin': min,
                                  'remark': remarkCtrl.text.trim().isEmpty
                                      ? null
                                      : remarkCtrl.text.trim(),
                                });
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                await _loadAll();
                                if (!mounted) return;
                                AppToast.success(context, '运动记录添加成功');
                              } on ApiException catch (e) {
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              } finally {
                                if (ctx.mounted) {
                                  setModal(() => submitting = false);
                                }
                              }
                            },
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
  }

  Future<void> _deleteRecord(dynamic id) async {
    if (id == null) return;
    try {
      await ApiService.delete('/exercise/records/$id');
      await _loadAll();
      if (!mounted) return;
      AppToast.success(context, '运动记录删除成功');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _fmt(dynamic t) {
    if (t is String) {
      final d = DateTime.tryParse(t);
      if (d != null) return DateFormat('MM-dd HH:mm').format(d.toLocal());
    }
    return '$t';
  }

  @override
  Widget build(BuildContext context) {
    final intake = _toDouble(_energyTip?['todayCalorieIntake']) ?? 0;
    final burned = _toDouble(_energyTip?['todayCalorieBurned']) ?? 0;
    final remaining = _toDouble(_energyTip?['remainingBurnKcal']) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动管理'),
        actions: [
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
          onTap: _showAdd,
          icon: Icons.add_rounded,
          label: '新增记录',
        ),
      ),
      body: HealthPageBackground(
        topTint: const Color(0xFFD9F1EE),
        accent: const Color(0xFFFFECD9),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: FrostPanel(
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
                        _error!,
                        style: const TextStyle(color: Color(0xFFC53A2E)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadAll,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    _hero(intake, burned, remaining),
                    const SizedBox(height: 14),
                    _energyCard(),
                    const SizedBox(height: 14),
                    _recordSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _hero(double intake, double burned, double remaining) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A887B), Color(0xFF2DA391), Color(0xFF77C7B6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B8A7D),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MM月dd日').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            '把今天摄入的热量\n变成可执行的运动节奏',
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
                  label: '摄入',
                  value: '${intake.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: HeroMetric(
                  label: '已消耗',
                  value: '${burned.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: HeroMetric(
                  label: '还需',
                  value: '${remaining.toStringAsFixed(0)} kcal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyCard() {
    if (_energyError != null) {
      return FrostPanel(
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFC53A2E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _energyError!,
                style: const TextStyle(color: Color(0xFFC53A2E)),
              ),
            ),
          ],
        ),
      );
    }

    final tip = _energyTip;
    if (tip == null) {
      return const SizedBox.shrink();
    }

    final summary = (tip['summary'] ?? '').toString();
    final suggestions = (tip['suggestions'] as List?) ?? const [];

    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '今日能量建议',
            subtitle: '根据饮食摄入和已完成运动，估算今天更适合的消耗方式',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftStatPill(
                text: '摄入 ${_numText(tip['todayCalorieIntake'])} kcal',
                bg: const Color(0xFFFFF1E8),
                fg: const Color(0xFF7A4C2C),
              ),
              SoftStatPill(
                text: '已消耗 ${_numText(tip['todayCalorieBurned'])} kcal',
              ),
              SoftStatPill(
                text: '建议消耗 ${_numText(tip['suggestedBurnKcal'])} kcal',
                bg: const Color(0xFFE8EEFF),
                fg: const Color(0xFF284C7C),
              ),
              SoftStatPill(
                text: '还需 ${_numText(tip['remainingBurnKcal'])} kcal',
                bg: const Color(0xFFFFF6DE),
                fg: const Color(0xFF7A5A1A),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF244543),
              ),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...suggestions.map((raw) {
              final item = _asMap(raw);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.58),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFE7F4F1),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFF0B8A7D),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['exerciseTypeName'] ?? '运动'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173A38),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '约 ${_numText(item['recommendedMinutes'])} 分钟 · 预计消耗 ${_numText(item['estimatedCalorieKcal'])} kcal',
                            style: const TextStyle(color: Color(0xFF597573)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _recordSection() {
    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '最近记录',
            subtitle: '把每次运动的时长、消耗和开始时间收拢到一个列表里',
          ),
          const SizedBox(height: 14),
          if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '暂无运动记录，去动一动吧',
                  style: TextStyle(color: Color(0xFF5A7673)),
                ),
              ),
            )
          else
            ..._records.map((raw) {
              final item = _asMap(raw);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withValues(alpha: 0.56),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFE5F4F1),
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: Color(0xFF0B8A7D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['exerciseTypeName'] ?? '运动'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173A38),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_numText(item['durationMin'])} 分钟 · ${_numText(item['calorieKcal'])} kcal',
                            style: const TextStyle(color: Color(0xFF4D6A67)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(item['startTime']),
                            style: const TextStyle(color: Color(0xFF7A908D)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteRecord(item['id']),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
