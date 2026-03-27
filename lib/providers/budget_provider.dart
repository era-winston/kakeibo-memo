import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBudgetKey = 'monthly_budget';

// SharedPreferences 経由で月予算を永続化する Notifier
class BudgetNotifier extends AsyncNotifier<double?> {
  @override
  Future<double?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_kBudgetKey);
    return v; // null = 未設定
  }

  Future<void> setBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBudgetKey, amount);
    state = AsyncData(amount);
  }

  Future<void> clearBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBudgetKey);
    state = const AsyncData(null);
  }
}

final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, double?>(BudgetNotifier.new);
