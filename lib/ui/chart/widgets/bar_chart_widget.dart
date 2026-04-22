import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction.dart';

class MonthlyBarChart extends StatefulWidget {
  final List<Transaction> allTransactions;

  const MonthlyBarChart({super.key, required this.allTransactions});

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  static final Color _incomeColor = AppColors.income.withValues(alpha: 0.8);
  static final Color _expenseColor = AppColors.expense.withValues(alpha: 0.8);

  int _monthCount = 6; // 3, 6, 12

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
        _monthCount, (i) => DateTime(now.year, now.month - (_monthCount - 1) + i));

    // Pre-group transactions into a month-keyed map for O(N+M) vs O(N×M)
    final totals = <String, (double, double)>{};
    for (final t in widget.allTransactions) {
      final key = '${t.date.year}-${t.date.month}';
      final (inc, exp) = totals[key] ?? (0.0, 0.0);
      totals[key] = t.isIncome ? (inc + t.amount, exp) : (inc, exp + t.amount);
    }

    final barWidth = _monthCount <= 6 ? 14.0 : 8.0;
    final groups = List.generate(months.length, (i) {
      final m = months[i];
      final (inc, exp) = totals['${m.year}-${m.month}'] ?? (0.0, 0.0);
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: inc,
            color: _incomeColor,
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: exp,
            color: _expenseColor,
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 4,
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 期間切替
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3ヶ月')),
                  ButtonSegment(value: 6, label: Text('6ヶ月')),
                  ButtonSegment(value: 12, label: Text('12ヶ月')),
                ],
                selected: {_monthCount},
                onSelectionChanged: (s) => setState(() => _monthCount = s.first),
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                showSelectedIcon: false,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legend(_incomeColor, '収入'),
                  const SizedBox(width: 12),
                  _legend(_expenseColor, '支出'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final m = months[v.toInt()];
                        final label = _monthCount <= 6
                            ? '${m.month}月'
                            : '${m.year % 100}/${m.month}';
                        return Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? '収入' : '支出';
                      return BarTooltipItem(
                        '$label\n¥${AppDateUtils.formatAmount(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12,
            color: AppColors.textSecondary)),
      ],
    );
  }
}
