import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/amount_field.dart';
import 'widgets/category_picker.dart';

class InputScreen extends ConsumerStatefulWidget {
  final Transaction? editTarget; // null = 新規

  const InputScreen({super.key, this.editTarget});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  late bool _isIncome;
  String? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final t = widget.editTarget;
    _isIncome = t?.isIncome ?? false;
    _selectedCategory = t?.category;
    _selectedDate = t?.date ?? DateTime.now();
    if (t != null) {
      _amountCtrl.text = t.amount.toInt().toString();
      _noteCtrl.text   = t.note;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final raw = _amountCtrl.text.replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  bool get _isValid =>
      _parsedAmount > 0 && _selectedCategory != null;

  Future<void> _save() async {
    if (!_isValid) return;
    final notifier = ref.read(transactionProvider.notifier);
    final t = Transaction(
      id: widget.editTarget?.id ?? const Uuid().v4(),
      amount: _parsedAmount,
      category: _selectedCategory!,
      isIncome: _isIncome,
      date: _selectedDate,
      note: _noteCtrl.text.trim(),
    );

    if (widget.editTarget != null) {
      await notifier.updateTransaction(t);
    } else {
      await notifier.add(t);
    }

    // 保存成功の触覚フィードバック
    HapticFeedback.lightImpact();

    if (mounted) {
      // 成功スナックバー
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(widget.editTarget == null ? '記録しました' : '更新しました'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('ja'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// 入力内容が初期値から変更されているか
  bool get _isDirty {
    final t = widget.editTarget;
    if (t == null) {
      // 新規: 何か入力されていれば dirty
      return _parsedAmount > 0 ||
          _selectedCategory != null ||
          _noteCtrl.text.isNotEmpty;
    }
    // 編集: 元の値と異なれば dirty
    return _parsedAmount != t.amount ||
        _selectedCategory != t.category ||
        _isIncome != t.isIncome ||
        _selectedDate != t.date ||
        _noteCtrl.text.trim() != t.note;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('入力内容を破棄しますか？'),
        content: const Text('保存されていない内容は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '破棄する',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok && mounted) nav.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.editTarget == null ? '収支を入力' : '編集'),
        actions: [
          TextButton(
            onPressed: _isValid ? _save : null,
            child: Text(
              '保存',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isValid ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 収入・支出トグル
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('支出'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('収入'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_isIncome},
              onSelectionChanged: (s) => setState(() {
                _isIncome = s.first;
                _selectedCategory = null;
              }),
            ),
            const SizedBox(height: 16),

            // 金額入力
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AmountField(
                controller: _amountCtrl,
                isIncome: _isIncome,
              ),
            ),
            const SizedBox(height: 16),

            // 日付
            ListTile(
              onTap: _pickDate,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textSecondary),
              title: Text(AppDateUtils.formatDate(_selectedDate)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              tileColor: Colors.transparent,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // カテゴリ
            const Text(
              'カテゴリ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            CategoryPicker(
              isIncome: _isIncome,
              selected: _selectedCategory,
              onSelected: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 16),

            // メモ
            TextField(
              controller: _noteCtrl,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '例: コンビニ、ランチなど',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _isValid ? _save : null,
              icon: const Icon(Icons.check),
              label: const Text('保存する'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      ), // end PopScope child: Scaffold
    ); // end PopScope
  }
}
