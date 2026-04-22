import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors_ext.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/date_utils.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, double> data;
  final double total;
  /// true = 収入グラフ用ラベル
  final bool isIncome;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.total,
    this.isIncome = false,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      final label = widget.isIncome ? '収入' : '支出';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 56, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              '$labelデータがありません',
              style: TextStyle(
                  color: context.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              '$labelを記録するとグラフが表示されます',
              style:
                  TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final touched = _touchedIndex >= 0 && _touchedIndex < entries.length
        ? entries[_touchedIndex]
        : null;

    final sections = List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: entries[i].value,
        color: AppCategories.colorFor(entries[i].key),
        radius: isTouched ? 72 : 60,
        showTitle: false,
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 64,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response!.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              // 中央: タッチ中はカテゴリ詳細、未タッチは合計
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: touched != null
                    ? _CenterDetail(
                        key: ValueKey(touched.key),
                        label: touched.key,
                        amount: touched.value,
                        pct: widget.total > 0
                            ? touched.value / widget.total * 100
                            : 0,
                        color: AppCategories.colorFor(touched.key),
                      )
                    : _CenterTotal(
                        key: const ValueKey('total'),
                        total: widget.total,
                        isIncome: widget.isIncome,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 凡例
        ...List.generate(entries.length, (i) {
          final e = entries[i];
          final pct = widget.total > 0
              ? (e.value / widget.total * 100).toStringAsFixed(1)
              : '0.0';
          final isTouched = i == _touchedIndex;
          final color = AppCategories.colorFor(e.key);
          return GestureDetector(
            onTap: () =>
                setState(() => _touchedIndex = isTouched ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isTouched
                    ? color.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isTouched ? 16 : 12,
                    height: isTouched ? 16 : 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isTouched
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: isTouched
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¥${AppDateUtils.formatAmount(e.value)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isTouched ? color : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── 中央表示ウィジェット ────────────────────────────────────────────────────────

class _CenterTotal extends StatelessWidget {
  final double total;
  final bool isIncome;
  const _CenterTotal({super.key, required this.total, this.isIncome = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isIncome ? '収入合計' : '支出合計',
          style: TextStyle(fontSize: 11, color: context.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '¥${AppDateUtils.formatAmount(total)}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CenterDetail extends StatelessWidget {
  final String label;
  final double amount;
  final double pct;
  final Color color;

  const _CenterDetail({
    super.key,
    required this.label,
    required this.amount,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '¥${AppDateUtils.formatAmount(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}
