import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _dbHelper.getTransactions();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addTransaction(TransactionModel transaction) async {
    final id = await _dbHelper.insertTransaction(transaction);
    await fetchTransactions();
    return id;
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await fetchTransactions();
  }
}
