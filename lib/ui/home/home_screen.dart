import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_colors_ext.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction.dart';
import '../../providers/filter_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import '../history/widgets/transaction_tile.dart';
import '../input/input_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(filterProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final notifier = ref.read(transactionProvider.notifier);
    final recurringAsync = ref.watch(recurringProvider);
    final templates = recurringAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
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
        actions: [
          // 検索
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          // 定期テンプレートクイック追加
          if (templates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.repeat),
              tooltip: '定期',
              onPressed: () =>
                  _showRecurringSheet(context, ref, templates, selectedMonth),
            ),
          // 設定
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (all) {
          final monthly = notifier.getByMonth(
            all, selectedMonth.year, selectedMonth.month,
          );
          final income = notifier.totalIncome(monthly);
          final expense = notifier.totalExpense(monthly);

          return ListView(
            children: [
              const SizedBox(height: 8),
              SummaryCard(income: income, expense: expense),
              const SizedBox(height: 16),
              if (monthly.isEmpty)
                const _EmptyState()
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4,
                  ),
                  child: Text(
                    '最近の取引',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                ...monthly.take(5).map((t) => TransactionTile(
                  transaction: t,
                  onDelete: () =>
                      ref.read(transactionProvider.notifier).delete(t.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InputScreen(editTarget: t),
                      fullscreenDialog: true,
                    ),
                  ),
                )),
                if (monthly.length > 5)
                  TextButton(
                    onPressed: () =>
                        ref.read(currentTabProvider.notifier).state = 1,
                    child: Text(
                      '${monthly.length - 5}件 もっと見る →',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showRecurringSheet(
    BuildContext context,
    WidgetRef ref,
    List<RecurringTemplate> templates,
    DateTime selectedMonth,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RecurringSheet(
        templates: templates,
        selectedMonth: selectedMonth,
      ),
    );
  }
}

// ── 定期テンプレート クイック追加シート ───────────────────────────────────────

class _RecurringSheet extends ConsumerWidget {
  final List<RecurringTemplate> templates;
  final DateTime selectedMonth;

  const _RecurringSheet({
    required this.templates,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('定期テンプレートから追加',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(AppDateUtils.formatMonth(selectedMonth),
                    style: TextStyle(
                        fontSize: 13, color: context.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...templates.map((t) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.isIncome
                      ? AppColors.incomeLight
                      : AppColors.expenseLight,
                  child: Text(t.isIncome ? '💰' : '📅'),
                ),
                title: Text(t.label),
                subtitle: Text(
                  '${t.isIncome ? '+' : '-'}¥${AppDateUtils.formatAmount(t.amount)}  ${t.category}',
                  style: TextStyle(
                      fontSize: 12, color: context.textSecondary),
                ),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final tx = Transaction(
                      id: const Uuid().v4(),
                      amount: t.amount,
                      category: t.category,
                      isIncome: t.isIncome,
                      date: DateTime(
                        selectedMonth.year,
                        selectedMonth.month,
                        DateTime.now().day
                            .clamp(1, AppDateUtils.lastDayOfMonth(selectedMonth).day),
                      ),
                      note: t.note,
                    );
                    await ref.read(transactionProvider.notifier).add(tx);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('「${t.label}」を記録しました'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('追加'),
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

// ── 空状態 ────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: context.textSecondary),
          const SizedBox(height: 12),
          Text(
            'まだ記録がありません',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '右下の + から収支を追加しましょう',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
