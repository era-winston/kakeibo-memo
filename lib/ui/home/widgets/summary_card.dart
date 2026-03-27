import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/budget_provider.dart';

class SummaryCard extends ConsumerWidget {
  final double income;
  final double expense;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _balanceRow(context, ref),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _amountColumn('収入', income, AppColors.income)),
                Container(
                    width: 1, height: 40, color: AppColors.divider),
                Expanded(
                    child:
                        _amountColumn('支出', expense, AppColors.expense)),
              ],
            ),

            // ── 予算進捗バー ────────────────────────────────────
            budgetAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (budget) {
                if (budget == null || budget <= 0) {
                  return const _BudgetSetButton();
                }
                return _BudgetBar(budget: budget, expense: expense);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(BuildContext context, WidgetRef ref) {
    final color = balance > 0
        ? AppColors.positive
        : balance < 0
            ? AppColors.negative
            : AppColors.neutral;

    return Column(
      children: [
        const Text(
          '残高',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        // カウントアップ風の数値表示
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: balance.abs()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Text(
            '¥${AppDateUtils.formatAmount(value)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Text(
            '¥${AppDateUtils.formatAmount(value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _BudgetBar extends ConsumerWidget {
  final double budget;
  final double expense;

  const _BudgetBar({
    required this.budget,
    required this.expense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = (expense / budget).clamp(0.0, 1.0);
    final over = expense > budget;
    final remaining = budget - expense;
    final barColor = ratio < 0.7
        ? AppColors.positive
        : ratio < 0.9
            ? const Color(0xFFFF8F00)
            : AppColors.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '月予算',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => _showBudgetDialog(context, ref, budget),
              child: Row(
                children: [
                  Text(
                    '¥${AppDateUtils.formatAmount(budget)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.edit_outlined,
                      size: 13, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          over
              ? '予算を ¥${AppDateUtils.formatAmount(expense - budget)} オーバー'
              : '残り ¥${AppDateUtils.formatAmount(remaining.abs())}',
          style: TextStyle(
            fontSize: 11,
            color: over ? AppColors.negative : AppColors.textSecondary,
            fontWeight: over ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _BudgetSetButton extends ConsumerWidget {
  const _BudgetSetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => _showBudgetDialog(context, ref, null),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 14, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              '月予算を設定する',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

void _showBudgetDialog(
    BuildContext context, WidgetRef ref, double? current) {
  final ctrl =
      TextEditingController(text: current != null ? current.toInt().toString() : '');

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('月予算を設定'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          prefixText: '¥ ',
          hintText: '例: 200000',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        if (current != null)
          TextButton(
            onPressed: () {
              ref.read(budgetProvider.notifier).clearBudget();
              Navigator.pop(ctx);
            },
            child: const Text('削除',
                style: TextStyle(color: AppColors.expense)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.replaceAll(',', ''));
            if (v != null && v > 0) {
              ref.read(budgetProvider.notifier).setBudget(v);
              Navigator.pop(ctx);
            }
          },
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}
