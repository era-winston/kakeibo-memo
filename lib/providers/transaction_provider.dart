import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

final repositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<List<Transaction>> build() async {
    return _repo.getAll();
  }

  Future<void> add(Transaction transaction) async {
    await _repo.add(transaction);
    ref.invalidateSelf();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repo.update(transaction);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    ref.invalidateSelf();
  }

  List<Transaction> getByMonth(List<Transaction> all, int year, int month) {
    return all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  double totalIncome(List<Transaction> monthly) =>
      monthly.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);

  double totalExpense(List<Transaction> monthly) =>
      monthly.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);

  Map<String, double> expenseByCategory(List<Transaction> monthly) {
    final map = <String, double>{};
    for (final t in monthly.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> incomeByCategory(List<Transaction> monthly) {
    final map = <String, double>{};
    for (final t in monthly.where((t) => t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
  TransactionNotifier.new,
);
