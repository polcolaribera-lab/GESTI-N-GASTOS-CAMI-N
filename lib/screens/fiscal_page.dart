import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class FiscalPage extends StatelessWidget {
  const FiscalPage({required this.expenses, super.key});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    final firstMonth = (quarter - 1) * 3 + 1;
    final quarterExpenses = expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month >= firstMonth &&
          expense.date.month < firstMonth + 3;
    }).toList();
    final deductible = quarterExpenses
        .where((item) => item.deductible)
        .toList();
    final deductibleBase = deductible.fold(
      0.0,
      (sum, item) => sum + item.deductibleBase,
    );
    final supportedVat = deductible.fold(
      0.0,
      (sum, item) => sum + item.deductibleVat,
    );
    final total = quarterExpenses.fold(0.0, (sum, item) => sum + item.amount);
    final missingReceipts = quarterExpenses
        .where((item) => !item.hasReceipt)
        .length;

    return CustomScrollView(
      key: const PageStorageKey('fiscal'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          sliver: SliverList.list(
            children: [
              PageHeader(
                title: 'Resumen fiscal',
                subtitle: 'Estimación para autónomos',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${quarter}T ${now.year}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _FiscalHero(
                supportedVat: supportedVat,
                deductibleBase: deductibleBase,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'GASTO TOTAL',
                      value: euro(total),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'DEDUCIBLES',
                      value: '${deductible.length}',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Evolución del trimestre',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _QuarterChart(
                expenses: quarterExpenses,
                firstMonth: firstMonth,
                year: now.year,
              ),
              const SizedBox(height: 28),
              Text(
                'Comprobaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      _CheckRow(
                        icon: missingReceipts == 0
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        color: missingReceipts == 0
                            ? AppColors.primary
                            : const Color(0xFFE08A47),
                        title: missingReceipts == 0
                            ? 'Justificantes al día'
                            : '$missingReceipts sin justificante',
                        subtitle: missingReceipts == 0
                            ? 'Todos los gastos tienen factura o ticket'
                            : 'Revísalos antes de presentar el trimestre',
                      ),
                      const Divider(height: 1),
                      _CheckRow(
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF6677B8),
                        title: 'Periodo ${quarter}T en curso',
                        subtitle: 'Incluye tres meses del año ${now.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.ink,
                      size: 21,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Estas cifras son orientativas. Confirma la deducibilidad y la liquidación con tu gestoría.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FiscalHero extends StatelessWidget {
  const _FiscalHero({required this.supportedVat, required this.deductibleBase});

  final double supportedVat;
  final double deductibleBase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Text(
                'IVA SOPORTADO DEDUCIBLE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            euro(supportedVat),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 37,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  'Base deducible',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  euro(deductibleBase),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 21),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuarterChart extends StatelessWidget {
  const _QuarterChart({
    required this.expenses,
    required this.firstMonth,
    required this.year,
  });

  final List<Expense> expenses;
  final int firstMonth;
  final int year;

  @override
  Widget build(BuildContext context) {
    final values = List.generate(3, (index) {
      final month = firstMonth + index;
      return expenses
          .where((item) => item.date.month == month)
          .fold(0.0, (sum, item) => sum + item.amount);
    });
    final maxValue = math.max(1.0, values.reduce(math.max));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: List.generate(3, (index) {
            final date = DateTime(year, firstMonth + index);
            final value = values[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 17),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      monthName(
                        date,
                        includeYear: false,
                      ).substring(0, 3).toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value / maxValue,
                        minHeight: 10,
                        color: index == 2
                            ? AppColors.accent
                            : AppColors.primary,
                        backgroundColor: AppColors.border.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  SizedBox(
                    width: 78,
                    child: Text(
                      euro(value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
