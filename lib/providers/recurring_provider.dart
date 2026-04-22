import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRecurringKey = 'recurring_templates';

class RecurringTemplate {
  final String id;
  final String label;
  final double amount;
  final String category;
  final bool isIncome;
  final String note;

  const RecurringTemplate({
    required this.id,
    required this.label,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'category': category,
        'isIncome': isIncome,
        'note': note,
      };

  factory RecurringTemplate.fromJson(Map<String, dynamic> j) =>
      RecurringTemplate(
        id: j['id'] as String,
        label: j['label'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        isIncome: j['isIncome'] as bool,
        note: j['note'] as String? ?? '',
      );
}

class RecurringNotifier
    extends AsyncNotifier<List<RecurringTemplate>> {
  @override
  Future<List<RecurringTemplate>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecurringKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => RecurringTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<RecurringTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRecurringKey,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> add(RecurringTemplate t) async {
    final current = state.valueOrNull ?? [];
    final next = [...current, t];
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? [];
    final next = current.where((t) => t.id != id).toList();
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> updateTemplate(RecurringTemplate t) async {
    final current = state.valueOrNull ?? [];
    final next = current.map((e) => e.id == t.id ? t : e).toList();
    state = AsyncData(next);
    await _save(next);
  }
}

final recurringProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringTemplate>>(
        RecurringNotifier.new);
