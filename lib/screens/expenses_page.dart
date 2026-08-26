import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/category_visuals.dart';
import '../widgets/expense_tile.dart';
import '../widgets/page_header.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({
    required this.expenses,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<Expense> expenses;
  final VoidCallback onAdd;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _searchController = TextEditingController();
  ExpenseCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> get _filteredExpenses {
    final query = _searchController.text.trim().toLowerCase();
    return widget.expenses.where((expense) {
      final matchesCategory =
          _category == null || expense.category == _category;
      final matchesSearch =
          query.isEmpty ||
          expense.description.toLowerCase().contains(query) ||
          expense.supplier.toLowerCase().contains(query) ||
          expense.attachments.any(
            (item) => item.name.toLowerCase().contains(query),
          );
      return matchesCategory && matchesSearch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('¿Eliminar este gasto?'),
        content: Text(
          'Se eliminará “${expense.description}” por ${euro(expense.amount)}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete(expense);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;
    final total = filtered.fold(0.0, (sum, item) => sum + item.amount);

    return CustomScrollView(
      key: const PageStorageKey('expenses'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          sliver: SliverList.list(
            children: [
              PageHeader(
                title: 'Mis gastos',
                subtitle: '${widget.expenses.length} movimientos guardados',
                trailing: IconButton.filled(
                  tooltip: 'Añadir gasto',
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar concepto o proveedor',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todos'),
                        selected: _category == null,
                        selectedColor: AppColors.mint,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    ...ExpenseCategory.values.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(categoryIcon(category), size: 16),
                          label: Text(category.label),
                          selected: _category == category,
                          selectedColor: AppColors.mint,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filtered.length} ${filtered.length == 1 ? 'resultado' : 'resultados'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    euro(total),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyResults(
              hasFilters:
                  _category != null || _searchController.text.isNotEmpty,
              onReset: () {
                _searchController.clear();
                setState(() => _category = null);
              },
              onAdd: widget.onAdd,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final expense = filtered[index];
                return Dismissible(
                  key: ValueKey(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.white),
                        SizedBox(height: 2),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => widget.onDelete(expense),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => widget.onEdit(expense),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: ExpenseTile(expense: expense),
                          ),
                        ),
                        const Divider(height: 1),
                        SizedBox(
                          height: 42,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => widget.onEdit(expense),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _confirmDelete(expense),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Eliminar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.hasFilters,
    required this.onReset,
    required this.onAdd,
  });

  final bool hasFilters;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters ? 'No hay coincidencias' : 'Aún no hay gastos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            hasFilters
                ? 'Prueba con otro texto o elimina los filtros.'
                : 'Añade tu primer gasto para empezar a ver el resumen.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: hasFilters ? onReset : onAdd,
            child: Text(hasFilters ? 'Quitar filtros' : 'Añadir un gasto'),
          ),
        ],
      ),
    );
  }
}
