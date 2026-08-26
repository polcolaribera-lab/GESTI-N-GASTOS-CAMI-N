import 'expense_attachment.dart';

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
    this.irpfRate = 0,
    this.prorationMonths = 1,
    this.attachments = const [],
  }) : assert(prorationMonths > 0);

  final String id;
  final String description;
  final String supplier;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final double vatRate;
  final bool deductible;
  final String paymentMethod;
  final double irpfRate;
  final int prorationMonths;
  final List<ExpenseAttachment> attachments;

  double get vatAmount => vatRate == 0 ? 0 : amount - baseAmount;
  double get baseAmount => amount / (1 + vatRate / 100);
  double get deductibleVat => deductible ? vatAmount : 0;
  double get deductibleBase => deductible ? baseAmount : 0;
  double get irpfAmount => baseAmount * irpfRate / 100;
  double get payableAmount => amount - irpfAmount;
  bool get isProrated => prorationMonths > 1;
  double get monthlyAmount => amount / prorationMonths;
  bool get hasReceipt => attachments.isNotEmpty;

  bool appliesToMonth(DateTime month) {
    final startMonth = date.year * 12 + date.month;
    final targetMonth = month.year * 12 + month.month;
    return targetMonth >= startMonth &&
        targetMonth < startMonth + prorationMonths;
  }

  double amountForMonth(DateTime month) {
    return appliesToMonth(month) ? monthlyAmount : 0;
  }

  double deductibleVatForMonth(DateTime month) {
    return appliesToMonth(month) ? deductibleVat / prorationMonths : 0;
  }

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
    'irpfRate': irpfRate,
    'hasReceipt': hasReceipt,
    'prorationMonths': prorationMonths,
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String?;
    final category = ExpenseCategory.values.firstWhere(
      (item) => item.name == categoryName,
      orElse: () => ExpenseCategory.other,
    );
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String? ?? 'Gasto',
      supplier: json['supplier'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: category,
      vatRate: (json['vatRate'] as num? ?? 0).toDouble(),
      deductible: json['deductible'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String? ?? 'Tarjeta',
      irpfRate: (json['irpfRate'] as num? ?? 0).toDouble(),
      prorationMonths:
          (json['prorationMonths'] as num?)?.toInt() ??
          (category == ExpenseCategory.insurance ? 12 : 1),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ExpenseAttachment.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
