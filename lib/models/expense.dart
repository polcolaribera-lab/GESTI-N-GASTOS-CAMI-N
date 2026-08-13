enum ExpenseCategory {
  fuel,
  tolls,
  maintenance,
  meals,
  insurance,
  taxes,
  parking,
  other,
}

extension ExpenseCategoryInfo on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.fuel => 'Combustible',
    ExpenseCategory.tolls => 'Peajes',
    ExpenseCategory.maintenance => 'Mantenimiento',
    ExpenseCategory.meals => 'Dietas',
    ExpenseCategory.insurance => 'Seguros',
    ExpenseCategory.taxes => 'Impuestos',
    ExpenseCategory.parking => 'Aparcamiento',
    ExpenseCategory.other => 'Otros',
  };
}

class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.supplier,
    required this.amount,
    required this.date,
    required this.category,
    required this.vatRate,
    required this.deductible,
    required this.paymentMethod,
    this.hasReceipt = true,
  });

  final String id;
  final String description;
  final String supplier;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final double vatRate;
  final bool deductible;
  final String paymentMethod;
  final bool hasReceipt;

  double get vatAmount => vatRate == 0 ? 0 : amount - baseAmount;
  double get baseAmount => amount / (1 + vatRate / 100);
  double get deductibleVat => deductible ? vatAmount : 0;
  double get deductibleBase => deductible ? baseAmount : 0;

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'supplier': supplier,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'vatRate': vatRate,
    'deductible': deductible,
    'paymentMethod': paymentMethod,
    'hasReceipt': hasReceipt,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String?;
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String? ?? 'Gasto',
      supplier: json['supplier'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: ExpenseCategory.values.firstWhere(
        (item) => item.name == categoryName,
        orElse: () => ExpenseCategory.other,
      ),
      vatRate: (json['vatRate'] as num? ?? 0).toDouble(),
      deductible: json['deductible'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String? ?? 'Tarjeta',
      hasReceipt: json['hasReceipt'] as bool? ?? true,
    );
  }
}
