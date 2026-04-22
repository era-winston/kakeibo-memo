import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_colors_ext.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../history/widgets/transaction_tile.dart';
import '../input/input_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _categoryFilter; // null = 全カテゴリ

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Transaction> _filter(List<Transaction> all) {
    if (_query.isEmpty && _categoryFilter == null) return [];
    final q = _query.toLowerCase();
    return all.where((t) {
      final matchCategory = _categoryFilter == null || t.category == _categoryFilter;
      if (!matchCategory) return false;
      if (q.isEmpty) return true;
      return t.category.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          AppDateUtils.formatDate(t.date).contains(q) ||
          t.amount.toInt().toString().contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // 使用中のカテゴリ一覧を取得
  List<String> _usedCategories(List<Transaction> all) {
    final seen = <String>{};
    final result = <String>[];
    for (final t in all) {
      if (seen.add(t.category)) result.add(t.category);
    }
    result.sort();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'カテゴリ・メモ・金額で検索',
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (all) {
          final usedCats = _usedCategories(all);
          final results = _filter(all);
          final isEmpty = _query.isEmpty && _categoryFilter == null;

          return Column(
            children: [
              // カテゴリチップフィルター
              if (usedCats.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('すべて'),
                        selected: _categoryFilter == null,
                        onSelected: (_) => setState(() => _categoryFilter = null),
                        visualDensity: VisualDensity.compact,
                      ),
                      ...usedCats.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          avatar: Text(AppCategories.emojiFor(cat),
                              style: const TextStyle(fontSize: 14)),
                          label: Text(cat),
                          selected: _categoryFilter == cat,
                          selectedColor:
                              AppCategories.colorFor(cat).withValues(alpha: 0.15),
                          checkmarkColor: AppCategories.colorFor(cat),
                          onSelected: (_) => setState(() =>
                              _categoryFilter = _categoryFilter == cat ? null : cat),
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                    ],
                  ),
                ),
              const Divider(height: 1),

              // 結果エリア
              Expanded(
                child: isEmpty
                    ? const _EmptyPrompt(
                        icon: Icons.search,
                        message: 'キーワードを入力してください',
                        sub: 'カテゴリチップでも絞り込めます',
                      )
                    : results.isEmpty
                        ? _EmptyPrompt(
                            icon: Icons.search_off_outlined,
                            message: _query.isNotEmpty
                                ? '「$_query」の検索結果はありません'
                                : '該当する取引がありません',
                            sub: '別のキーワードやカテゴリをお試しください',
                          )
                        : Column(
                            children: [
                              // 件数バナー
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                color: AppColors.primaryLight,
                                child: Text(
                                  '${results.length}件 ヒット',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: results.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, indent: 72),
                                  itemBuilder: (context, i) {
                                    final t = results[i];
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
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyPrompt({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: context.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
