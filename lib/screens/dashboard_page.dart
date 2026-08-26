import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/category_visuals.dart';
import '../widgets/expense_tile.dart';
import '../widgets/page_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.expenses,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onAdd,
    required this.onEdit,
    required this.onSeeAll,
    super.key,
  });

  final List<Expense> expenses;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onAdd;
  final ValueChanged<Expense> onEdit;
  final VoidCallback onSeeAll;

  static const _monthlyBudget = 2500.0;

  @override
  Widget build(BuildContext context) {
    final monthlyExpenses =
        expenses
            .where((expense) => expense.appliesToMonth(selectedMonth))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final total = monthlyExpenses.fold(
      0.0,
      (sum, item) => sum + item.amountForMonth(selectedMonth),
    );
    final deductible = monthlyExpenses
        .where((item) => item.deductible)
        .fold(0.0, (sum, item) => sum + item.amountForMonth(selectedMonth));
    final vat = monthlyExpenses.fold(
      0.0,
      (sum, item) => sum + item.deductibleVatForMonth(selectedMonth),
    );

    return CustomScrollView(
      key: const PageStorageKey('dashboard'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          sliver: SliverList.list(
            children: [
              PageHeader(
                title: 'RutaClara',
                subtitle: 'Tu negocio, bajo control',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Autónomo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _MonthSelector(
                month: selectedMonth,
                onPrevious: onPreviousMonth,
                onNext: onNextMonth,
              ),
              const SizedBox(height: 16),
              _BudgetCard(
                total: total,
                budget: _monthlyBudget,
                expenseCount: monthlyExpenses.length,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'DEDUCIBLE',
                      amount: deductible,
                      icon: Icons.verified_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'IVA SOPORTADO',
                      amount: vat,
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF6677B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Añadir gasto'),
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle(title: 'Gasto por categoría'),
              const SizedBox(height: 12),
              _CategoryBreakdown(
                expenses: monthlyExpenses,
                total: total,
                selectedMonth: selectedMonth,
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Costes imputados del mes',
                action: monthlyExpenses.isEmpty ? null : 'Ver todos',
                onAction: onSeeAll,
              ),
              const SizedBox(height: 8),
              if (monthlyExpenses.isEmpty)
                _EmptyMonth(onAdd: onAdd)
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < math.min(3, monthlyExpenses.length);
                          index++
                        ) ...[
                          InkWell(
                            onTap: () => onEdit(monthlyExpenses[index]),
                            borderRadius: BorderRadius.circular(14),
                            child: ExpenseTile(
                              expense: monthlyExpenses[index],
                              compact: true,
                              editable: true,
                              displayAmount: monthlyExpenses[index]
                                  .amountForMonth(selectedMonth),
                            ),
                          ),
                          if (index < math.min(3, monthlyExpenses.length) - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final name = monthName(month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(
          tooltip: 'Mes anterior',
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
        ),
        Column(
          children: [
            Text(
              name[0].toUpperCase() + name.substring(1),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Resumen mensual',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        _RoundIconButton(
          tooltip: 'Mes siguiente',
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border.withValues(alpha: 0.45),
        side: const BorderSide(color: AppColors.border),
      ),
      icon: Icon(icon),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.total,
    required this.budget,
    required this.expenseCount,
  });

  final double total;
  final double budget;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final progress = (total / budget).clamp(0.0, 1.0);
    final remaining = budget - total;

    return Container(
      height: 218,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            width: 190,
            height: 190,
            right: -68,
            top: -80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            width: 100,
            height: 100,
            right: 48,
            bottom: -60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 18,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'COSTE IMPUTADO DEL MES',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$expenseCount ${expenseCount == 1 ? 'gasto' : 'gastos'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  euro(total),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 38,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      remaining >= 0 ? 'Disponible' : 'Exceso',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      euro(remaining.abs()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    color: remaining >= 0 ? AppColors.accent : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Límite mensual ${euro(budget, showDecimals: false)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                euro(amount),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.expenses,
    required this.total,
    required this.selectedMonth,
  });

  final List<Expense> expenses;
  final double total;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Las categorías aparecerán aquí cuando añadas gastos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (amount) => amount + expense.amountForMonth(selectedMonth),
        ifAbsent: () => expense.amountForMonth(selectedMonth),
      );
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          children: rows.take(4).map((entry) {
            final percentage = total == 0 ? 0.0 : entry.value / total;
            final color = categoryColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(categoryIcon(entry.key), size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        euro(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CategoryBadge(category: ExpenseCategory.other, size: 52),
            const SizedBox(height: 12),
            Text(
              'Un mes sin gastos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Añade el primer movimiento para empezar el seguimiento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(onPressed: onAdd, child: const Text('Añadir ahora')),
          ],
        ),
      ),
    );
  }
}
