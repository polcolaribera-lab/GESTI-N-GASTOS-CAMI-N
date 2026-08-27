import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({String? userId})
    : _userId = userId,
      _storageKey = userId == null
          ? _legacyStorageKey
          : '${_legacyStorageKey}_$userId';

  static const _legacyStorageKey = 'ruta_clara_expenses_v1';
  static const _legacyOwnerKey = 'ruta_clara_expenses_v1_owner';

  final String? _userId;
  final String _storageKey;

  Future<List<Expense>> loadExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    var storedValue = preferences.getString(_storageKey);

    if (storedValue == null && _userId != null) {
      final legacyValue = preferences.getString(_legacyStorageKey);
      final legacyOwner = preferences.getString(_legacyOwnerKey);
      if (legacyValue != null &&
          (legacyOwner == null || legacyOwner == _userId)) {
        await preferences.setString(_legacyOwnerKey, _userId);
        await preferences.setString(_storageKey, legacyValue);
        storedValue = legacyValue;
      }
    }

    if (storedValue == null) {
      final examples = _exampleExpenses();
      await saveExpenses(examples);
      return examples;
    }

    try {
      final decoded = jsonDecode(storedValue) as List<dynamic>;
      return decoded
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } on FormatException {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(expenses.map((item) => item.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
  }

  Future<void> deleteAll() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);

    if (_userId != null && preferences.getString(_legacyOwnerKey) == _userId) {
      await preferences.remove(_legacyStorageKey);
      await preferences.remove(_legacyOwnerKey);
    }
  }

  List<Expense> _exampleExpenses() {
    final now = DateTime.now();
    DateTime day(int value) => DateTime(now.year, now.month, value);
    final safeDay = now.day;

    return [
      Expense(
        id: 'example-fuel',
        description: 'Repostaje',
        supplier: 'Estación Norte',
        amount: 186.40,
        date: day(safeDay > 2 ? safeDay - 1 : safeDay),
        category: ExpenseCategory.fuel,
        vatRate: 21,
        deductible: true,
        paymentMethod: 'Tarjeta',
      ),
      Expense(
        id: 'example-toll',
        description: 'Peaje AP-7',
        supplier: 'Autopistas',
        amount: 23.75,
        date: day(safeDay > 4 ? safeDay - 3 : 1),
        category: ExpenseCategory.tolls,
        vatRate: 21,
        deductible: true,
        paymentMethod: 'Vía-T',
      ),
      Expense(
        id: 'example-meal',
        description: 'Menú en ruta',
        supplier: 'Área La Mancha',
        amount: 14.50,
        date: day(safeDay > 5 ? safeDay - 4 : 1),
        category: ExpenseCategory.meals,
        vatRate: 10,
        deductible: true,
        paymentMethod: 'Efectivo',
      ),
      Expense(
        id: 'example-workshop',
        description: 'Cambio de aceite',
        supplier: 'Talleres MotorSur',
        amount: 342.90,
        date: day(safeDay > 7 ? safeDay - 6 : 1),
        category: ExpenseCategory.maintenance,
        vatRate: 21,
        deductible: true,
        paymentMethod: 'Tarjeta',
      ),
    ];
  }
}
