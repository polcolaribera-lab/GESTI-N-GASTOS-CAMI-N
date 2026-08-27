import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_service.dart';
import '../data/attachment_repository.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../services/gestoria_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_form.dart';
import 'dashboard_page.dart';
import 'expenses_page.dart';
import 'fiscal_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.repository,
    required this.attachmentRepository,
    required this.user,
    required this.onSignOut,
    required this.onDeleteAccount,
    super.key,
  });

  final ExpenseRepository repository;
  final AttachmentRepository attachmentRepository;
  final AuthUser user;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

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

  Future<void> _showExpenseForm([Expense? existingExpense]) async {
    final isEditing = existingExpense != null;
    final result = await showModalBottomSheet<ExpenseFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.surface,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ExpenseForm(
        expense: existingExpense,
        attachmentRepository: widget.attachmentRepository,
      ),
    );

    if (result == null || !mounted) return;
    final expense = result.expense;
    final retainedIds = expense.attachments.map((item) => item.id).toSet();
    final removedAttachmentIds =
        existingExpense?.attachments
            .where((item) => !retainedIds.contains(item.id))
            .map((item) => item.id) ??
        const Iterable<String>.empty();

    try {
      await widget.attachmentRepository.saveAll(result.newFiles);
      await widget.attachmentRepository.deleteAll(removedAttachmentIds);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron guardar los justificantes.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      final updatedExpenses = [..._expenses];
      final existingIndex = updatedExpenses.indexWhere(
        (item) => item.id == expense.id,
      );
      if (existingIndex >= 0) {
        updatedExpenses[existingIndex] = expense;
      } else {
        updatedExpenses.add(expense);
      }
      _expenses = updatedExpenses..sort((a, b) => b.date.compareTo(a.date));
      _selectedMonth = DateTime(expense.date.year, expense.date.month);
    });
    await widget.repository.saveExpenses(_expenses);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Gasto actualizado correctamente'
              : 'Gasto guardado correctamente',
        ),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
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
    await controller.closed;
    if (!restored) {
      await widget.attachmentRepository.deleteAll(
        expense.attachments.map((item) => item.id),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final attachmentIds = _expenses
        .expand((expense) => expense.attachments)
        .map((attachment) => attachment.id)
        .toList();

    await widget.onDeleteAccount();
    await Future.wait([
      widget.attachmentRepository.deleteAll(attachmentIds),
      widget.repository.deleteAll(),
    ]);
  }

  Future<void> _exportCurrentQuarter() async {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    try {
      final package = await GestoriaExportService(widget.attachmentRepository)
          .buildQuarterPackage(
            expenses: _expenses,
            year: now.year,
            quarter: quarter,
          );
      if (!mounted) return;
      if (package.expenseCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay gastos en el ${quarter}T de ${now.year}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(package.bytes, mimeType: 'application/zip')],
          fileNameOverrides: [package.fileName],
          title: 'Exportación Ruta Clara',
          subject: 'Gastos ${quarter}T ${now.year}',
          text:
              'Paquete de gastos y justificantes de Ruta Clara · ${quarter}T ${now.year}',
          downloadFallbackEnabled: true,
        ),
      );
      if (!mounted) return;
      final documentWarning = package.withoutDigitalReceiptCount == 0
          ? ''
          : ' · ${package.withoutDigitalReceiptCount} sin documento digital';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paquete preparado: ${package.attachmentCount} justificantes$documentWarning',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear la exportación para la gestoría.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  onAdd: () => _showExpenseForm(),
                  onEdit: _showExpenseForm,
                  onSeeAll: () => setState(() => _selectedIndex = 1),
                ),
                ExpensesPage(
                  expenses: _expenses,
                  onAdd: () => _showExpenseForm(),
                  onEdit: _showExpenseForm,
                  onDelete: _deleteExpense,
                ),
                FiscalPage(
                  expenses: _expenses,
                  onExport: _exportCurrentQuarter,
                ),
                ProfilePage(
                  user: widget.user,
                  onSignOut: widget.onSignOut,
                  onDeleteAccount: _deleteAccount,
                ),
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
          Text('Ruta Clara', style: Theme.of(context).textTheme.titleLarge),
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
