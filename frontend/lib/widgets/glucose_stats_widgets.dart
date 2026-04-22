// ============================================================
// 新增文件：frontend/lib/widgets/glucose_stats_widgets.dart
// 包含 TIR 环形图组件 和 HbA1c 估算 Banner
// 在 glucose_screen.dart 和 report_screen.dart 中引入即可
// ============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../widgets/premium_health_ui.dart';

/// TIR（Time-In-Range）环形图卡片
/// 传入 [records] 每条记录的血糖值列表，以及 [targetMin] [targetMax] 目标范围
class TirCard extends StatelessWidget {
  const TirCard({
    super.key,
    required this.values,
    required this.targetMin,
    required this.targetMax,
  });

  final List<double> values;
  final double targetMin;
  final double targetMax;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final inRange = values
        .where((v) => v >= targetMin && v <= targetMax)
        .length;
    final high = values.where((v) => v > targetMax).length;
    final low = values.where((v) => v < targetMin).length;
    final total = values.length;

    final inPct = (inRange / total * 100).round();
    final highPct = (high / total * 100).round();
    final lowPct = 100 - inPct - highPct;

    return FrostPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '血糖达标时间（TIR）', subtitle: '在目标范围内的时间占比'),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: [
                      PieChartSectionData(
                        value: inRange.toDouble(),
                        color: const Color(0xFF0B8A7D),
                        radius: 26,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: high.toDouble(),
                        color: const Color(0xFFC53A2E),
                        radius: 22,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: low.toDouble(),
                        color: const Color(0xFFE08A22),
                        radius: 22,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      color: const Color(0xFF0B8A7D),
                      label: '达标',
                      pct: inPct,
                      count: inRange,
                    ),
                    const SizedBox(height: 8),
                    _legendRow(
                      color: const Color(0xFFC53A2E),
                      label: '偏高',
                      pct: highPct,
                      count: high,
                    ),
                    const SizedBox(height: 8),
                    _legendRow(
                      color: const Color(0xFFE08A22),
                      label: '偏低',
                      pct: lowPct,
                      count: low,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 进度条可视化
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (inRange > 0)
                  Expanded(
                    flex: inRange,
                    child: Container(height: 8, color: const Color(0xFF0B8A7D)),
                  ),
                if (high > 0)
                  Expanded(
                    flex: high,
                    child: Container(height: 8, color: const Color(0xFFC53A2E)),
                  ),
                if (low > 0)
                  Expanded(
                    flex: low,
                    child: Container(height: 8, color: const Color(0xFFE08A22)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '目标：TIR ≥ 70%  当前：$inPct%',
            style: TextStyle(
              fontSize: 12,
              color: inPct >= 70
                  ? const Color(0xFF0B8A7D)
                  : const Color(0xFFC53A2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required int pct,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5A7673)),
        ),
        const Spacer(),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($count次)',
          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA8A6)),
        ),
      ],
    );
  }
}

/// HbA1c 估算 Banner
/// 传入当前统计窗口的平均血糖值（mmol/L）。
class HbA1cBanner extends StatelessWidget {
  const HbA1cBanner({super.key, required this.avgGlucose, this.dayCount = 1});

  final double avgGlucose;
  final int dayCount;

  /// ADAG 估算公式：HbA1c(%) = (平均血糖 mmol/L + 2.59) / 1.59
  double get _estimated => (avgGlucose + 2.59) / 1.59;

  String get _riskLabel {
    final v = _estimated;
    if (v < 5.7) return '正常';
    if (v < 6.5) return '偏高（糖尿病前期参考值）';
    return '偏高（建议就医复查）';
  }

  Color get _riskColor {
    final v = _estimated;
    if (v < 5.7) return const Color(0xFF0B8A7D);
    if (v < 6.5) return const Color(0xFFE08A22);
    return const Color(0xFFC53A2E);
  }

  @override
  Widget build(BuildContext context) {
    return FrostPanel(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _estimated.toStringAsFixed(1),
                style: TextStyle(
                  color: _riskColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HbA1c 估算值 (%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173836),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _riskLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '基于当前页面约$dayCount天统计窗口的平均血糖 ${avgGlucose.toStringAsFixed(1)} mmol/L 估算，仅供参考；正式 HbA1c 请以近3个月化验或长期均值为准',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA8A6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 使用方法：在 glucose_screen.dart 的 build() 中，
// 在 _adviceCard() 之前插入：
//
//   if (_records.isNotEmpty) ...[
//     const SizedBox(height: 12),
//     TirCard(
//       values: _records
//           .map((r) => _toDouble(r['valueMmolL']) ?? 0.0)
//           .where((v) => v > 0)
//           .toList(),
//       targetMin: _targetMin,
//       targetMax: _targetMax,
//     ),
//   ],
//
// 在趋势图卡片之后插入 HbA1c Banner（需要先计算近90天均值）：
//
//   if (_stats.avg != null) ...[
//     const SizedBox(height: 12),
//     HbA1cBanner(avgGlucose: _stats.avg!),
//   ],
// ============================================================
