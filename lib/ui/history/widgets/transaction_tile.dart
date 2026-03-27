import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_colors_ext.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('削除の確認'),
          content: const Text('この取引を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                '削除',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expense,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: t.isIncome
              ? AppColors.incomeLight
              : AppColors.expenseLight,
          child: Text(
            AppCategories.emojiFor(t.category),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          t.category,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.note.isNotEmpty)
              Text(
                t.note,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              AppDateUtils.formatDate(t.date),
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: t.note.isNotEmpty,
        trailing: Text(
          '${t.isIncome ? '+' : '-'}¥${AppDateUtils.formatAmount(t.amount)}',
          style: TextStyle(
            color: t.isIncome ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
