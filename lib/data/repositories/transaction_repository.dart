import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class TransactionRepository {
  static const String _boxName = 'transactions';

  Box<Transaction> get _box => Hive.box<Transaction>(_boxName);

  Future<void> add(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> update(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  List<Transaction> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
