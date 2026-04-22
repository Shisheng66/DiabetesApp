import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../widgets/premium_health_ui.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final GlobalKey _captureKey = GlobalKey();

  List<Map<String, dynamic>> _points = [];
  Map<String, dynamic>? _dietRec;
  Map<String, dynamic>? _dietAnalysis;
  String? _dietRecError;
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  DateTime _date = DateTime.now();

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
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final trend = await ApiService.get(
        '/blood-glucose/trend/daily',
        query: {'date': dateStr},
      );

      Map<String, dynamic>? rec;
      String? recErr;
      try {
        rec = await ApiService.get(
          '/diet/recommendations/daily',
          query: {'date': dateStr},
        );
      } on ApiException catch (e) {
        recErr = e.message;
      } catch (_) {
        recErr = '饮食推荐加载失败';
      }

      Map<String, dynamic>? analysis;
      try {
        analysis = await ApiService.get(
          '/diet/analysis/daily',
          query: {'date': dateStr},
        );
      } catch (_) {
        analysis = null;
      }

      final rows = (trend['points'] as List?) ?? const [];
      setState(() {
        _points = rows.map(_asMap).toList();
        _dietRec = rec;
        _dietAnalysis = analysis;
        _dietRecError = recErr;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _onExportSelected(String action) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      if (action == 'image') {
        await _exportImage();
      } else if (action == 'weekly_pdf') {
        await _exportPdf(period: 'weekly');
      } else if (action == 'monthly_pdf') {
        await _exportPdf(period: 'monthly');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出失败，请稍后重试')));
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _exportImage() async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('报告页面未完全加载，请稍后再试')));
      return;
    }

    final image = await boundary.toImage(pixelRatio: 2.8);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('capture bytes failed');
    }

    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(_date);
    final path = '${dir.path}/health_report_$date.png';
    final file = File(path);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    await Share.shareXFiles([
      XFile(path),
    ], text: '健康报告 ${DateFormat('yyyy-MM-dd').format(_date)}');
  }

  Future<void> _exportPdf({required String period}) async {
    final points = await _loadPeriodPoints(period);
    final stats = _computeStats(points);
    final periodTitle = period == 'weekly' ? 'Weekly' : 'Monthly';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('Diabetes $periodTitle Report')),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(_date)}'),
            pw.SizedBox(height: 8),
            pw.Bullet(text: 'Records: ${stats.count}'),
            pw.Bullet(text: 'Average: ${stats.avg.toStringAsFixed(2)} mmol/L'),
            pw.Bullet(text: 'Max: ${stats.max.toStringAsFixed(2)} mmol/L'),
            pw.Bullet(text: 'Min: ${stats.min.toStringAsFixed(2)} mmol/L'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Time', 'Glucose (mmol/L)'],
              data: points
                  .map((p) => [p.timeLabel, p.value.toStringAsFixed(2)])
                  .toList(),
            ),
            if (_dietRec != null) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Diet Recommendation',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text((_dietRec!['summary'] ?? '').toString()),
            ],
          ];
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(_date);
    final path = '${dir.path}/health_${period}_$date.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(path)], text: '$periodTitle health report');
  }

  Future<List<_ReportPoint>> _loadPeriodPoints(String period) async {
    Map<String, dynamic> res;
    if (period == 'weekly') {
      final weekStart = _date.subtract(Duration(days: _date.weekday - 1));
      res = await ApiService.get(
        '/blood-glucose/trend/weekly',
        query: {'weekStart': DateFormat('yyyy-MM-dd').format(weekStart)},
      );
    } else {
      res = await ApiService.get(
        '/blood-glucose/trend/monthly',
        query: {'year': _date.year.toString(), 'month': _date.month.toString()},
      );
    }

    final rows = (res['points'] as List?) ?? const [];
    return rows
        .map(_asMap)
        .map(
          (e) => _ReportPoint(
            timeLabel: (e['time'] ?? '').toString(),
            value: _toDouble(e['value']) ?? 0,
          ),
        )
        .toList();
  }

  _ReportStats _computeStats(List<_ReportPoint> points) {
    if (points.isEmpty) {
      return const _ReportStats(count: 0, avg: 0, min: 0, max: 0);
    }
    final values = points.map((e) => e.value).toList();
    final sum = values.reduce((a, b) => a + b);
    return _ReportStats(
      count: values.length,
      avg: sum / values.length,
      min: values.reduce(min),
      max: values.reduce(max),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康报告'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '导出',
            onSelected: _onExportSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'image', child: Text('导出图片')),
              PopupMenuItem(value: 'weekly_pdf', child: Text('导出周报 PDF')),
              PopupMenuItem(value: 'monthly_pdf', child: Text('导出月报 PDF')),
            ],
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1F1EE), Color(0xFFF4F8F7)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorPane(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      Text(
                        '血糖日趋势 · ${DateFormat('yyyy-MM-dd').format(_date)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                          child: _points.isEmpty
                              ? const SizedBox(
                                  height: 200,
                                  child: Center(child: Text('当天暂无血糖趋势数据')),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 220, child: _lineChart()),
                                    const SizedBox(height: 10),
                                    _summaryRow(),
                                  ],
                                ),
                        ),
                      ),
                      if (_points.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '明细点位',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ..._points.map((item) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item['time']?.toString() ?? '-'),
                              trailing: Text(
                                '${item['value']} mmol/L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        color: const Color(0xFFE8F6F3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                color: Color(0xFF0B8A7D),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '每日饮食推荐：结合当日血糖与饮食数据，供日常参考（不能替代医嘱）。',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF2D3E3C),
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_dietAnalysis != null) ...[
                        _nutritionReportCard(),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        '今日饮食建议',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_dietRecError != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _dietRecError!,
                              style: const TextStyle(color: Color(0xFFC53A2E)),
                            ),
                          ),
                        )
                      else if (_dietRec != null)
                        _dietRecommendationCard(context)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _lineChart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _points.length; i++) {
      final item = _points[i];
      final value = _toDouble(item['value']) ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final yValues = spots.map((e) => e.y).toList();
    final minY = yValues.reduce(min);
    final maxY = yValues.reduce(max);
    final pad = max(0.8, (maxY - minY) * 0.2);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_points.length - 1).toDouble(),
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: max(0.5, ((maxY + pad) - (minY - pad)) / 4),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
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
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(value.toStringAsFixed(1)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _points.length <= 2 ? 1 : ((_points.length - 1) / 2),
              getTitlesWidget: (value, _) {
                final index = value.round();
                if (index < 0 || index >= _points.length) {
                  return const SizedBox.shrink();
                }
                final label = (_points[index]['time'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label.length > 5 ? label.substring(0, 5) : label,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF0B8A7D),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                return FlDotCirclePainter(
                  radius: 3.8,
                  color: const Color(0xFF0B8A7D),
                  strokeWidth: 1.6,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B8A7D).withValues(alpha: 0.25),
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

  Widget _summaryRow() {
    final values = _points
        .map((e) => _toDouble(e['value']))
        .whereType<double>()
        .toList();
    final avg = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('次数 ${values.length}'),
        _chip('均值 ${avg.toStringAsFixed(1)} mmol/L'),
        _chip(
          '最高 ${values.isEmpty ? '-' : values.reduce(max).toStringAsFixed(1)}',
        ),
        _chip(
          '最低 ${values.isEmpty ? '-' : values.reduce(min).toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _dietRecommendationCard(BuildContext context) {
    final r = _dietRec!;
    final summary = (r['summary'] ?? '').toString();
    final tips = (r['tips'] as List?) ?? const [];
    final foods = (r['recommendedFoods'] as List?) ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.isNotEmpty)
              Text(
                summary,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tips.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: Color(0xFF0B8A7D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('$t', style: const TextStyle(height: 1.35)),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (foods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '推荐食物（低 GI / 优质蛋白）',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...foods.map((raw) {
                final f = _asMap(raw);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '· ${f['name'] ?? ''} - ${f['calorieKcalPer100g'] ?? '--'} kcal/100g · 碳水 ${f['carbGPer100g'] ?? '--'}g',
                    style: const TextStyle(color: Color(0xFF2D3E3C)),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nutritionReportCard() {
    final analysis = _dietAnalysis!;
    final score = (_toDouble(analysis['score']) ?? 0).round();
    final grade = '${analysis['grade'] ?? '待评估'}';
    final headline = '${analysis['headline'] ?? '营养管家已生成今日建议'}';
    final summary = '${analysis['summary'] ?? ''}';
    final advice = '${analysis['nextMealAdvice'] ?? ''}';
    final risks = ((analysis['riskFlags'] as List?) ?? const [])
        .take(3)
        .toList();
    final actions = ((analysis['actionItems'] as List?) ?? const [])
        .take(3)
        .toList();
    final fiber = analysis['estimatedFiberG'];
    final averageGi = analysis['averageGi'];

    return FrostPanel(
      tint: const Color(0xFFFFF8EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B8A7D), Color(0xFF78C6B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      '营养评估 · $grade',
                      style: const TextStyle(
                        color: Color(0xFF0B6F66),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173836),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(height: 1.35, color: Color(0xFF35514E)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('纤维 ${fiber ?? '--'}g'),
              _chip('平均 GI ${averageGi ?? '--'}'),
              ...risks.map((risk) => _chip('$risk')),
            ],
          ),
          if (advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFF0B8A7D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        color: Color(0xFF1F5E59),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '行动清单',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...actions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFF0B8A7D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$item',
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1F6A63),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', v));
    }
    return const <String, dynamic>{};
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

class _ReportPoint {
  const _ReportPoint({required this.timeLabel, required this.value});

  final String timeLabel;
  final double value;
}

class _ReportStats {
  const _ReportStats({
    required this.count,
    required this.avg,
    required this.min,
    required this.max,
  });

  final int count;
  final double avg;
  final double min;
  final double max;
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

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
          Text(message, style: const TextStyle(color: Color(0xFFC53A2E))),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
