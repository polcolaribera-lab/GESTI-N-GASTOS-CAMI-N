import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import 'category_visuals.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    required this.expense,
    super.key,
    this.compact = false,
    this.editable = false,
    this.displayAmount,
  });

  final Expense expense;
  final bool compact;
  final bool editable;
  final double? displayAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 9 : 11),
      child: Row(
        children: [
          CategoryBadge(category: expense.category, size: compact ? 42 : 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: compact ? 14 : 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${expense.supplier} · ${shortDate(expense.date)}${expense.attachments.isEmpty ? '' : ' · ${expense.attachments.length} adj.'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                euro(displayAmount ?? expense.amount),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: compact ? 14 : 15),
              ),
              const SizedBox(height: 3),
              if (expense.isProrated)
                Text(
                  '${expense.prorationMonths} meses · ${euro(expense.monthlyAmount)}/mes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: expense.deductible
                            ? AppColors.primary
                            : AppColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      expense.deductible ? 'Deducible' : 'No deducible',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: expense.deductible
                            ? AppColors.primary
                            : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (editable) ...[
            const SizedBox(width: 7),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
          ],
        ],
      ),
    );
  }
}
