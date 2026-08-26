import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_clara/data/expense_repository.dart';
import 'package:ruta_clara/models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'el primer usuario conserva los gastos anteriores al inicio de sesión',
    () async {
      SharedPreferences.setMockInitialValues({});
      final legacyRepository = ExpenseRepository();
      final previousExpense = Expense(
        id: 'previous-expense',
        description: 'Gasto anterior',
        supplier: 'Proveedor',
        amount: 42,
        date: DateTime(2026, 8, 20),
        category: ExpenseCategory.other,
        vatRate: 21,
        deductible: true,
        paymentMethod: 'Tarjeta',
      );
      await legacyRepository.saveExpenses([previousExpense]);

      final firstUserExpenses = await ExpenseRepository(
        userId: 'first-user',
      ).loadExpenses();
      final secondUserExpenses = await ExpenseRepository(
        userId: 'second-user',
      ).loadExpenses();

      expect(firstUserExpenses.single.id, 'previous-expense');
      expect(
        secondUserExpenses.any((expense) => expense.id == 'previous-expense'),
        isFalse,
      );
    },
  );
}
