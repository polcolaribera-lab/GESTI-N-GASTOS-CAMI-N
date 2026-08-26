import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_clara/models/expense.dart';
import 'package:ruta_clara/models/expense_attachment.dart';

void main() {
  group('prorrateo de seguros', () {
    test('reparte un seguro anual entre doce meses', () {
      final insurance = Expense(
        id: 'insurance-1',
        description: 'Seguro anual',
        supplier: 'Aseguradora',
        amount: 1200,
        date: DateTime(2025, 12, 15),
        category: ExpenseCategory.insurance,
        vatRate: 0,
        deductible: true,
        paymentMethod: 'Banco',
        prorationMonths: 12,
      );

      expect(insurance.monthlyAmount, 100);
      expect(insurance.appliesToMonth(DateTime(2025, 12)), isTrue);
      expect(insurance.appliesToMonth(DateTime(2026, 11)), isTrue);
      expect(insurance.appliesToMonth(DateTime(2026, 12)), isFalse);
      expect(insurance.amountForMonth(DateTime(2026, 5)), 100);
    });

    test('los seguros antiguos se migran como anuales', () {
      final insurance = Expense.fromJson({
        'id': 'legacy-insurance',
        'description': 'Seguro antiguo',
        'supplier': 'Aseguradora',
        'amount': 600,
        'date': '2026-01-10T00:00:00.000',
        'category': 'insurance',
        'vatRate': 0,
        'deductible': true,
        'paymentMethod': 'Banco',
      });

      expect(insurance.prorationMonths, 12);
      expect(insurance.monthlyAmount, 50);
    });
  });

  test('conserva los justificantes al serializar un gasto', () {
    final expense = Expense(
      id: 'expense-with-file',
      description: 'Peaje',
      supplier: 'Autopista',
      amount: 25,
      date: DateTime(2026, 8, 14),
      category: ExpenseCategory.tolls,
      vatRate: 21,
      deductible: true,
      paymentMethod: 'Vía-T',
      attachments: const [
        ExpenseAttachment(
          id: 'invoice-pdf',
          name: 'factura.pdf',
          mimeType: 'application/pdf',
          size: 2048,
        ),
      ],
    );

    final restored = Expense.fromJson(expense.toJson());

    expect(restored.attachments, hasLength(1));
    expect(restored.attachments.single.name, 'factura.pdf');
    expect(restored.attachments.single.size, 2048);
  });
}
