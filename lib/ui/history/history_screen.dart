import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction.dart';
import '../../providers/filter_provider.dart';
import '../../providers/transaction_provider.dart';
import '../input/input_screen.dart';
import 'widgets/transaction_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool? _filterIsIncome; // null=全て, true=収入, false=支出

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(filterProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final notifier = ref.read(transactionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  ref.read(filterProvider.notifier).previousMonth(),
            ),
            Text(AppDateUtils.formatMonth(selectedMonth)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  ref.read(filterProvider.notifier).nextMonth(),
            ),
          ],
        ),
      ),
      body: transactionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (all) {
          var monthly = notifier.getByMonth(
            all, selectedMonth.year, selectedMonth.month,
          );

          if (_filterIsIncome != null) {
            monthly = monthly
                .where((t) => t.isIncome == _filterIsIncome)
                .toList();
          }

          // 日付グルーピング: 同日のアイテムをまとめる
          final grouped = _groupByDate(monthly);

          return Column(
            children: [
              // フィルターチップ
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('すべて'),
                      selected: _filterIsIncome == null,
                      onSelected: (_) =>
                          setState(() => _filterIsIncome = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('収入'),
                      selected: _filterIsIncome == true,
                      selectedColor: AppColors.incomeLight,
                      onSelected: (_) =>
                          setState(() => _filterIsIncome = true),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('支出'),
                      selected: _filterIsIncome == false,
                      selectedColor: AppColors.expenseLight,
                      onSelected: (_) =>
                          setState(() => _filterIsIncome = false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: monthly.isEmpty
                    ? const Center(
                        child: Text('該当する取引がありません',
                            style: TextStyle(
                                color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: grouped.length,
                        itemBuilder: (context, i) {
                          final item = grouped[i];
                          if (item is _DateHeader) {
                            return _buildDateHeader(item);
                          }
                          final t = (item as _TransactionItem).transaction;
                          return TransactionTile(
                            transaction: t,
                            onDelete: () => ref
                                .read(transactionProvider.notifier)
                                .delete(t.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InputScreen(editTarget: t),
                                fullscreenDialog: true,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(_DateHeader header) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            header.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AppColors.divider),
          ),
          const SizedBox(width: 8),
          Text(
            header.dayTotal >= 0
                ? '+¥${AppDateUtils.formatAmount(header.dayTotal)}'
                : '-¥${AppDateUtils.formatAmount(header.dayTotal.abs())}',
            style: TextStyle(
              fontSize: 11,
              color: header.dayTotal >= 0
                  ? AppColors.income
                  : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 日付でグループ化してヘッダー+アイテムのフラットリストを生成 O(n)
  List<Object> _groupByDate(List<Transaction> transactions) {
    // Pass 1: 日付キーごとの合計を事前計算
    final totals = <String, double>{};
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      totals[key] = (totals[key] ?? 0) + (t.isIncome ? t.amount : -t.amount);
    }

    // Pass 2: ヘッダー+アイテムのフラットリストを生成
    final result = <Object>[];
    String? lastDateKey;
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      if (key != lastDateKey) {
        result.add(_DateHeader(
          label: AppDateUtils.formatDate(t.date),
          dayTotal: totals[key]!,
        ));
        lastDateKey = key;
      }
      result.add(_TransactionItem(t));
    }
    return result;
  }
}

class _DateHeader {
  final String label;
  final double dayTotal;
  _DateHeader({required this.label, required this.dayTotal});
}

class _TransactionItem {
  final Transaction transaction;
  _TransactionItem(this.transaction);
}
