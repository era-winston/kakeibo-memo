import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/filter_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils/date_utils.dart';
import 'widgets/pie_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';

class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(filterProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final notifier = ref.read(transactionProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出内訳'),
              Tab(text: '収入内訳'),
              Tab(text: '月次推移'),
            ],
          ),
        ),
        body: transactionsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (all) {
            final monthly = notifier.getByMonth(
                all, selectedMonth.year, selectedMonth.month);
            final byExpenseCategory = notifier.expenseByCategory(monthly);
            final byIncomeCategory = notifier.incomeByCategory(monthly);
            final totalExpense = notifier.totalExpense(monthly);
            final totalIncome = notifier.totalIncome(monthly);

            return TabBarView(
              children: [
                // 支出内訳
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CategoryPieChart(
                    data: byExpenseCategory,
                    total: totalExpense,
                  ),
                ),
                // 収入内訳
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CategoryPieChart(
                    data: byIncomeCategory,
                    total: totalIncome,
                    isIncome: true,
                  ),
                ),
                // 月次推移
                SingleChildScrollView(
                  child: MonthlyBarChart(allTransactions: all),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
