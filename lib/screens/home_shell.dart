import 'package:flutter/material.dart';

import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_form.dart';
import 'dashboard_page.dart';
import 'expenses_page.dart';
import 'fiscal_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.repository, super.key});

  final ExpenseRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _loading = true;
  List<Expense> _expenses = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await widget.repository.loadExpenses();
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _loading = false;
    });
  }

  Future<void> _showExpenseForm() async {
    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.surface,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const ExpenseForm(),
    );

    if (expense == null || !mounted) return;
    setState(() {
      _expenses = [..._expenses, expense]
        ..sort((a, b) => b.date.compareTo(a.date));
      _selectedMonth = DateTime(expense.date.year, expense.date.month);
    });
    await widget.repository.saveExpenses(_expenses);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gasto guardado correctamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final originalIndex = _expenses.indexWhere((item) => item.id == expense.id);
    if (originalIndex < 0) return;

    setState(() => _expenses.removeAt(originalIndex));
    await widget.repository.saveExpenses(_expenses);
    if (!mounted) return;

    var restored = false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Gasto eliminado'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'DESHACER',
            onPressed: () async {
              if (restored || !mounted) return;
              restored = true;
              setState(() {
                final insertAt = originalIndex.clamp(0, _expenses.length);
                _expenses.insert(insertAt, expense);
              });
              await widget.repository.saveExpenses(_expenses);
            },
          ),
        ),
      );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return;
    }
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      body: _loading
          ? const _LoadingView()
          : IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardPage(
                  expenses: _expenses,
                  selectedMonth: _selectedMonth,
                  onPreviousMonth: _previousMonth,
                  onNextMonth: isCurrentMonth ? null : _nextMonth,
                  onAdd: _showExpenseForm,
                  onSeeAll: () => setState(() => _selectedIndex = 1),
                ),
                ExpensesPage(
                  expenses: _expenses,
                  onAdd: _showExpenseForm,
                  onDelete: _deleteExpense,
                ),
                FiscalPage(expenses: _expenses),
                const ProfilePage(),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard_rounded),
                    label: 'Resumen',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: 'Gastos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_outlined),
                    selectedIcon: Icon(Icons.account_balance_rounded),
                    label: 'Fiscal',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.business_outlined),
                    selectedIcon: Icon(Icons.business_rounded),
                    label: 'Mi negocio',
                  ),
                ],
              ),
            ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          Text('RutaClara', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 15),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }
}
