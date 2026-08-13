import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';

IconData categoryIcon(ExpenseCategory category) => switch (category) {
  ExpenseCategory.fuel => Icons.local_gas_station_rounded,
  ExpenseCategory.tolls => Icons.toll_rounded,
  ExpenseCategory.maintenance => Icons.build_rounded,
  ExpenseCategory.meals => Icons.restaurant_rounded,
  ExpenseCategory.insurance => Icons.health_and_safety_rounded,
  ExpenseCategory.taxes => Icons.account_balance_rounded,
  ExpenseCategory.parking => Icons.local_parking_rounded,
  ExpenseCategory.other => Icons.receipt_long_rounded,
};

Color categoryColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.fuel => const Color(0xFF2F7D72),
  ExpenseCategory.tolls => const Color(0xFF6677B8),
  ExpenseCategory.maintenance => const Color(0xFFE08A47),
  ExpenseCategory.meals => const Color(0xFFC46C76),
  ExpenseCategory.insurance => const Color(0xFF4C86A8),
  ExpenseCategory.taxes => const Color(0xFF7967A8),
  ExpenseCategory.parking => const Color(0xFF528D5D),
  ExpenseCategory.other => AppColors.muted,
};

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.category, super.key, this.size = 46});

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(categoryIcon(category), color: color, size: size * 0.5),
    );
  }
}
