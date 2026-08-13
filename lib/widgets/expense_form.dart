import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import 'category_visuals.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.fuel;
  DateTime _date = DateTime.now();
  double _vatRate = 21;
  bool _deductible = true;
  bool _hasReceipt = true;
  String _paymentMethod = 'Tarjeta';

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _descriptionController.dispose();
    _supplierController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
      helpText: 'FECHA DEL GASTO',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.of(context).pop(
      Expense(
        id: '${now.microsecondsSinceEpoch}',
        description: _descriptionController.text.trim(),
        supplier: _supplierController.text.trim(),
        amount: _amount,
        date: _date,
        category: _category,
        vatRate: _vatRate,
        deductible: _deductible,
        paymentMethod: _paymentMethod,
        hasReceipt: _hasReceipt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final base = _vatRate == 0 ? _amount : _amount / (1 + _vatRate / 100);
    final vat = _amount - base;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo gasto',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Regístralo en menos de un minuto',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      _FieldLabel(label: 'Categoría'),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ExpenseCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 9),
                          itemBuilder: (context, index) {
                            final category = ExpenseCategory.values[index];
                            final selected = category == _category;
                            return InkWell(
                              onTap: () => setState(() => _category = category),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 88,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.mint
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      categoryIcon(category),
                                      color: selected
                                          ? AppColors.primary
                                          : categoryColor(category),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      category.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.primaryDark
                                            : AppColors.ink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(label: 'Concepto y proveedor'),
                      TextFormField(
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Concepto',
                          hintText: 'Ej. Repostaje',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe un concepto'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _supplierController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor',
                          hintText: 'Ej. Estación Norte',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el proveedor'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(label: 'Importe total'),
                      TextFormField(
                        controller: _amountController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          hintText: '0,00',
                          suffixText: '€',
                          prefixIcon: Icon(Icons.euro_rounded),
                        ),
                        validator: (value) {
                          if (_amount <= 0) {
                            return 'Introduce un importe válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(date: _date, onTap: _pickDate),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Pago',
                                prefixIcon: Icon(Icons.credit_card_rounded),
                              ),
                              items:
                                  const [
                                        'Tarjeta',
                                        'Efectivo',
                                        'Vía-T',
                                        'Banco',
                                      ]
                                      .map(
                                        (method) => DropdownMenuItem(
                                          value: method,
                                          child: Text(method),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _paymentMethod = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(label: 'IVA incluido'),
                      Wrap(
                        spacing: 8,
                        children: [0.0, 10.0, 21.0].map((rate) {
                          return ChoiceChip(
                            label: Text('${rate.toInt()} %'),
                            selected: _vatRate == rate,
                            selectedColor: AppColors.mint,
                            checkmarkColor: AppColors.primary,
                            onSelected: (_) => setState(() => _vatRate = rate),
                          );
                        }).toList(),
                      ),
                      if (_amount > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calculate_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Base ${euro(base)}  ·  IVA ${euro(vat)}',
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _SwitchRow(
                        icon: Icons.verified_rounded,
                        title: 'Gasto deducible',
                        subtitle: 'Cuenta para la estimación fiscal',
                        value: _deductible,
                        onChanged: (value) =>
                            setState(() => _deductible = value),
                      ),
                      _SwitchRow(
                        icon: Icons.receipt_rounded,
                        title: 'Tengo justificante',
                        subtitle: 'Factura o ticket guardado',
                        value: _hasReceipt,
                        onChanged: (value) =>
                            setState(() => _hasReceipt = value),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Guardar gasto'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          prefixIcon: Icon(Icons.calendar_today_rounded),
        ),
        child: Text(fullDate(date), maxLines: 1),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
