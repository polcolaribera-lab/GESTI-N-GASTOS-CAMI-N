import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/formatters.dart';
import '../data/attachment_repository.dart';
import '../models/expense.dart';
import '../models/expense_attachment.dart';
import '../theme/app_theme.dart';
import 'category_visuals.dart';

class ExpenseFormResult {
  const ExpenseFormResult({required this.expense, required this.newFiles});

  final Expense expense;
  final Map<String, Uint8List> newFiles;
}

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    required this.attachmentRepository,
    super.key,
    this.expense,
  });

  final Expense? expense;
  final AttachmentRepository attachmentRepository;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Map<String, Uint8List> _newFiles = {};
  List<ExpenseAttachment> _attachments = [];

  ExpenseCategory _category = ExpenseCategory.fuel;
  DateTime _date = DateTime.now();
  double _vatRate = 21;
  bool _deductible = true;
  String _paymentMethod = 'Tarjeta';
  int _prorationMonths = 1;
  bool _pickingAttachment = false;

  bool get _isEditing => widget.expense != null;

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) return;

    _descriptionController.text = expense.description;
    _supplierController.text = expense.supplier;
    _amountController.text = expense.amount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _category = expense.category;
    _date = expense.date;
    _vatRate = expense.vatRate;
    _deductible = expense.deductible;
    _paymentMethod = expense.paymentMethod;
    _prorationMonths = expense.prorationMonths;
    _attachments = [...expense.attachments];
  }

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

  Future<void> _withAttachmentPicker(Future<void> Function() action) async {
    if (_pickingAttachment) return;
    setState(() => _pickingAttachment = true);
    try {
      await action();
    } on PlatformException catch (error) {
      _showMessage(
        error.code.contains('camera')
            ? 'No se pudo acceder a la cámara.'
            : 'No se pudo seleccionar el archivo.',
        isError: true,
      );
    } catch (_) {
      _showMessage('No se pudo guardar el justificante.', isError: true);
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  Future<void> _takePhoto() async {
    await _withAttachmentPicker(() async {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      _addAttachment(
        photo.name,
        bytes,
        mimeType: photo.mimeType ?? 'image/jpeg',
      );
    });
  }

  Future<void> _pickImages() async {
    await _withAttachmentPicker(() async {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
        limit: 10,
        requestFullMetadata: false,
      );
      for (final image in images) {
        final bytes = await image.readAsBytes();
        _addAttachment(
          image.name,
          bytes,
          mimeType: image.mimeType ?? _mimeTypeForName(image.name),
        );
      }
    });
  }

  Future<void> _pickFiles() async {
    await _withAttachmentPicker(() async {
      const acceptedTypes = XTypeGroup(
        label: 'Facturas y justificantes',
        extensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        mimeTypes: [
          'application/pdf',
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/heic',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ],
      );
      final files = await openFiles(acceptedTypeGroups: [acceptedTypes]);
      for (final file in files) {
        final bytes = await file.readAsBytes();
        _addAttachment(file.name, bytes, mimeType: _mimeTypeForName(file.name));
      }
    });
  }

  void _addAttachment(
    String name,
    Uint8List bytes, {
    required String mimeType,
  }) {
    const maxFileSize = 15 * 1024 * 1024;
    const maxTotalSize = 50 * 1024 * 1024;
    if (bytes.length > maxFileSize) {
      _showMessage('$name supera el límite de 15 MB.', isError: true);
      return;
    }
    final totalSize = _attachments.fold(0, (sum, item) => sum + item.size);
    if (_attachments.length >= 20 || totalSize + bytes.length > maxTotalSize) {
      _showMessage(
        'El gasto admite hasta 20 archivos y 50 MB en total.',
        isError: true,
      );
      return;
    }

    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${_attachments.length}';
    final attachment = ExpenseAttachment(
      id: id,
      name: name.isEmpty ? 'Justificante' : name,
      mimeType: mimeType,
      size: bytes.length,
    );
    setState(() {
      _attachments.add(attachment);
      _newFiles[id] = bytes;
    });
  }

  void _removeAttachment(ExpenseAttachment attachment) {
    setState(() {
      _attachments.removeWhere((item) => item.id == attachment.id);
      _newFiles.remove(attachment.id);
    });
  }

  Future<void> _previewAttachment(ExpenseAttachment attachment) async {
    final bytes =
        _newFiles[attachment.id] ??
        await widget.attachmentRepository.load(attachment.id);
    if (!mounted) return;

    if (attachment.isImage && bytes != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(_attachmentIcon(attachment), color: AppColors.primary),
        title: Text(attachment.name, textAlign: TextAlign.center),
        content: Text(
          '${_attachmentTypeLabel(attachment)} · ${_formatBytes(attachment.size)}\n\nEl archivo está guardado junto a este gasto.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ExpenseFormResult(
        newFiles: Map.unmodifiable(_newFiles),
        expense: Expense(
          id: widget.expense?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
          description: _descriptionController.text.trim(),
          supplier: _supplierController.text.trim(),
          amount: _amount,
          date: _date,
          category: _category,
          vatRate: _vatRate,
          deductible: _deductible,
          paymentMethod: _paymentMethod,
          prorationMonths: _category == ExpenseCategory.insurance
              ? _prorationMonths
              : 1,
          attachments: List.unmodifiable(_attachments),
        ),
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
                            _isEditing ? 'Editar gasto' : 'Nuevo gasto',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing
                                ? 'Actualiza los datos del movimiento'
                                : 'Regístralo en menos de un minuto',
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
                              onTap: () {
                                setState(() {
                                  final wasInsurance =
                                      _category == ExpenseCategory.insurance;
                                  _category = category;
                                  if (category == ExpenseCategory.insurance &&
                                      !wasInsurance) {
                                    _prorationMonths = 12;
                                    _vatRate = 0;
                                  } else if (category !=
                                      ExpenseCategory.insurance) {
                                    _prorationMonths = 1;
                                    if (wasInsurance && _vatRate == 0) {
                                      _vatRate = 21;
                                    }
                                  }
                                });
                              },
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
                      if (_category == ExpenseCategory.insurance) ...[
                        _FieldLabel(label: 'Periodo cubierto por el seguro'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              const {
                                1: 'Mensual',
                                3: 'Trimestral',
                                6: 'Semestral',
                                12: 'Anual',
                              }.entries.map((option) {
                                return ChoiceChip(
                                  label: Text(option.value),
                                  selected: _prorationMonths == option.key,
                                  selectedColor: AppColors.mint,
                                  checkmarkColor: AppColors.primary,
                                  onSelected: (_) => setState(
                                    () => _prorationMonths = option.key,
                                  ),
                                );
                              }).toList(),
                        ),
                        if (_amount > 0) ...[
                          const SizedBox(height: 11),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_view_month_rounded,
                                  color: AppColors.ink,
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Coste mensual: ${euro(_amount / _prorationMonths)} durante $_prorationMonths ${_prorationMonths == 1 ? 'mes' : 'meses'}',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
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
                        subtitle: _attachments.isEmpty
                            ? 'Añade una foto o archivo del ticket o factura'
                            : '${_attachments.length} ${_attachments.length == 1 ? 'justificante adjunto' : 'justificantes adjuntos'}',
                        value: _attachments.isNotEmpty,
                        onChanged: null,
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(
                        label: 'Facturas y tickets (${_attachments.length})',
                      ),
                      Text(
                        'Haz una foto o selecciona varios documentos. Se guardarán dentro de este gasto.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickingAttachment ? null : _takePhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Hacer foto'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickingAttachment ? null : _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Imágenes'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickingAttachment ? null : _pickFiles,
                            icon: const Icon(Icons.attach_file_rounded),
                            label: const Text('Archivos'),
                          ),
                        ],
                      ),
                      if (_pickingAttachment) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(minHeight: 3),
                      ],
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._attachments.map(
                          (attachment) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttachmentTile(
                              attachment: attachment,
                              bytes: _newFiles[attachment.id],
                              onPreview: () => _previewAttachment(attachment),
                              onDelete: () => _removeAttachment(attachment),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: Icon(
                          _isEditing ? Icons.save_outlined : Icons.add_rounded,
                        ),
                        label: Text(
                          _isEditing ? 'Guardar cambios' : 'Guardar gasto',
                        ),
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onPreview,
    required this.onDelete,
    this.bytes,
  });

  final ExpenseAttachment attachment;
  final Uint8List? bytes;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPreview,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(11),
                ),
                clipBehavior: Clip.antiAlias,
                child: attachment.isImage && bytes != null
                    ? Image.memory(
                        bytes!,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                        errorBuilder: (_, _, _) => Icon(
                          _attachmentIcon(attachment),
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        _attachmentIcon(attachment),
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_attachmentTypeLabel(attachment)} · ${_formatBytes(attachment.size)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ver justificante',
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Quitar justificante',
                onPressed: onDelete,
                color: AppColors.danger,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
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

String _mimeTypeForName(String name) {
  final extension = name.toLowerCase().split('.').last;
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    _ => 'application/octet-stream',
  };
}

String _attachmentTypeLabel(ExpenseAttachment attachment) {
  if (attachment.isImage) return 'Imagen';
  if (attachment.mimeType == 'application/pdf') return 'PDF';
  if (attachment.mimeType.contains('word')) return 'Documento';
  if (attachment.mimeType.contains('excel') ||
      attachment.mimeType.contains('spreadsheet')) {
    return 'Hoja de cálculo';
  }
  return 'Archivo';
}

IconData _attachmentIcon(ExpenseAttachment attachment) {
  if (attachment.isImage) return Icons.image_outlined;
  if (attachment.mimeType == 'application/pdf') {
    return Icons.picture_as_pdf_outlined;
  }
  if (attachment.mimeType.contains('spreadsheet') ||
      attachment.mimeType.contains('excel')) {
    return Icons.table_chart_outlined;
  }
  return Icons.description_outlined;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
  final ValueChanged<bool>? onChanged;

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
