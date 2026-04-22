import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_colors_ext.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/csv_export.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import 'passcode_screen.dart';

const _privacyPolicyUrl = 'https://kakeibomemo.com/privacy';
const _termsUrl = 'https://kakeibomemo.com/terms';

const _themeModeLabels = {
  ThemeMode.system: 'システムに合わせる',
  ThemeMode.light: 'ライト',
  ThemeMode.dark: 'ダーク',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final passcodeAsync = ref.watch(passcodeProvider);
    final recurringAsync = ref.watch(recurringProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final hasPasscode = passcodeAsync.valueOrNull != null;
    final templates = recurringAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // ── 外観 ──────────────────────────────────────────────
          const _SectionHeader(label: '外観'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('テーマ'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          // ── データ管理 ────────────────────────────────────────
          const _SectionHeader(label: 'データ管理'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('CSVでエクスポート'),
            subtitle: const Text('全データをファイルに書き出して共有'),
            onTap: () async {
              final all = transactionsAsync.valueOrNull ?? [];
              if (all.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('エクスポートするデータがありません')),
                );
                return;
              }
              await CsvExport.exportAndShare(all);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.expense),
            title: const Text('すべてのデータを削除',
                style: TextStyle(color: AppColors.expense)),
            subtitle: const Text('取引・予算・テンプレートを完全に削除します'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),

          // ── セキュリティ ──────────────────────────────────────
          const _SectionHeader(label: 'セキュリティ'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('パスコードロック'),
            subtitle: Text(hasPasscode ? '設定済み' : '未設定'),
            value: hasPasscode,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => _onPasscodeToggle(context, ref, v),
          ),

          // ── 定期テンプレート ───────────────────────────────────
          const _SectionHeader(label: '定期テンプレート'),
          ...templates.map((t) => _TemplateTile(template: t)),
          ListTile(
            leading: const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
            title: const Text(
              'テンプレートを追加',
              style: TextStyle(color: AppColors.primary),
            ),
            onTap: () => _showAddTemplateSheet(context, ref),
          ),
          if (templates.isNotEmpty) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '※ ホーム画面の「定期」ボタンからワンタップで記録できます',
                style: TextStyle(
                    fontSize: 12, color: context.textSecondary),
              ),
            ),
          ],

          // ── アプリについて ────────────────────────────────────
          const _SectionHeader(label: 'アプリについて'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(_privacyPolicyUrl),
                mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(_termsUrl),
                mode: LaunchMode.externalApplication),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('バージョン'),
            trailing: Text('1.0.0',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode m) => _themeModeLabels[m]!;

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('すべてのデータを削除'),
        content: const Text(
          'すべての取引データ・予算設定・定期テンプレートが完全に削除されます。\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ref.read(transactionProvider.notifier).deleteAll();
    await ref.read(budgetProvider.notifier).clearBudget();
    // テンプレートを全削除
    final templates = ref.read(recurringProvider).valueOrNull ?? [];
    for (final t in templates) {
      await ref.read(recurringProvider.notifier).remove(t.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのデータを削除しました')),
      );
    }
  }

  Future<void> _onPasscodeToggle(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const PasscodeSetScreen(),
          fullscreenDialog: true,
        ),
      );
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('パスコードを設定しました'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('パスコードを削除'),
          content: const Text('パスコードロックを無効にしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(passcodeProvider.notifier).clearPasscode();
      }
    }
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
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
            ...ThemeMode.values.map((m) => ListTile(
                  title: Text(_themeModeLabels[m]!),
                  trailing: m == current
                      ? const Icon(Icons.check,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(m);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddTemplateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _AddTemplateSheet(),
    );
  }
}

// ── テンプレートタイル ─────────────────────────────────────────────────────────

class _TemplateTile extends ConsumerWidget {
  final RecurringTemplate template;

  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = template;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            t.isIncome ? AppColors.incomeLight : AppColors.expenseLight,
        child: Text(AppCategories.emojiFor(t.category)),
      ),
      title: Text(t.label),
      subtitle: Text(
        '${t.isIncome ? '+' : '-'}¥${AppDateUtils.formatAmount(t.amount)}  ${t.category}',
        style: TextStyle(fontSize: 12, color: context.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () => _showEditTemplateSheet(context, t),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () => ref.read(recurringProvider.notifier).remove(t.id),
          ),
        ],
      ),
    );
  }

  void _showEditTemplateSheet(BuildContext context, RecurringTemplate t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddTemplateSheet(editTarget: t),
    );
  }
}

// ── テンプレート追加シート ────────────────────────────────────────────────────

class _AddTemplateSheet extends ConsumerStatefulWidget {
  final RecurringTemplate? editTarget;
  const _AddTemplateSheet({this.editTarget});

  @override
  ConsumerState<_AddTemplateSheet> createState() =>
      _AddTemplateSheetState();
}

class _AddTemplateSheetState extends ConsumerState<_AddTemplateSheet> {
  late final _labelCtrl = TextEditingController(text: widget.editTarget?.label ?? '');
  late final _amountCtrl = TextEditingController(
    text: widget.editTarget != null ? widget.editTarget!.amount.toInt().toString() : '',
  );
  late final _noteCtrl = TextEditingController(text: widget.editTarget?.note ?? '');
  late bool _isIncome = widget.editTarget?.isIncome ?? false;
  late String? _category = widget.editTarget?.category;

  bool get _isEditing => widget.editTarget != null;

  bool get _isValid {
    final v = double.tryParse(_amountCtrl.text);
    return _labelCtrl.text.isNotEmpty && v != null && v > 0 && _category != null;
  }

  Future<void> _submit() async {
    final t = RecurringTemplate(
      id: widget.editTarget?.id ?? const Uuid().v4(),
      label: _labelCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      category: _category!,
      isIncome: _isIncome,
      note: _noteCtrl.text.trim(),
    );
    if (_isEditing) {
      await ref.read(recurringProvider.notifier).updateTemplate(t);
    } else {
      await ref.read(recurringProvider.notifier).add(t);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _isIncome ? AppCategories.income : AppCategories.expense;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? 'テンプレートを編集' : 'テンプレートを追加',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // 名前
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'テンプレート名（例: 家賃）',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // 収入/支出トグル
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('支出')),
              ButtonSegment(value: true, label: Text('収入')),
            ],
            selected: {_isIncome},
            onSelectionChanged: (s) => setState(() {
              _isIncome = s.first;
              _category = null;
            }),
          ),
          const SizedBox(height: 12),

          // 金額
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '金額',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // カテゴリ選択（横スクロール）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final sel = _category == cat.name;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = cat.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? (_isIncome
                              ? AppColors.incomeLight
                              : AppColors.expenseLight)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? (_isIncome
                                ? AppColors.income
                                : AppColors.expense)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji),
                        const SizedBox(width: 4),
                        Text(cat.name,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // メモ
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'メモ（任意）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _isValid ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_isEditing ? '更新する' : '追加する'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
