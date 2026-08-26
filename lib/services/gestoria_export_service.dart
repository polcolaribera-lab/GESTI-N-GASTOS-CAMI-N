import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../core/formatters.dart';
import '../data/attachment_repository.dart';
import '../models/expense.dart';

class GestoriaExportPackage {
  const GestoriaExportPackage({
    required this.fileName,
    required this.bytes,
    required this.expenseCount,
    required this.attachmentCount,
    required this.withoutDigitalReceiptCount,
  });

  final String fileName;
  final Uint8List bytes;
  final int expenseCount;
  final int attachmentCount;
  final int withoutDigitalReceiptCount;
}

class GestoriaExportService {
  const GestoriaExportService(this.attachmentRepository);

  final AttachmentRepository attachmentRepository;

  Future<GestoriaExportPackage> buildQuarterPackage({
    required List<Expense> expenses,
    required int year,
    required int quarter,
  }) async {
    assert(quarter >= 1 && quarter <= 4);
    final firstMonth = (quarter - 1) * 3 + 1;
    final periodExpenses = expenses.where((expense) {
      return expense.date.year == year &&
          expense.date.month >= firstMonth &&
          expense.date.month < firstMonth + 3;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final archive = Archive();
    final csv = _buildCsv(periodExpenses);
    archive.add(
      ArchiveFile.bytes(
        'gastos_${quarter}T_$year.csv',
        utf8.encode('\uFEFF$csv'),
      ),
    );

    var attachmentCount = 0;
    var withoutDigitalReceiptCount = 0;
    final missingStoredFiles = <String>[];

    for (final expense in periodExpenses) {
      if (expense.attachments.isEmpty) {
        withoutDigitalReceiptCount++;
        continue;
      }

      final folder = _expenseFolder(expense);
      for (var index = 0; index < expense.attachments.length; index++) {
        final attachment = expense.attachments[index];
        final bytes = await attachmentRepository.load(attachment.id);
        if (bytes == null) {
          missingStoredFiles.add('${expense.description}: ${attachment.name}');
          continue;
        }

        attachmentCount++;
        final sequence = (index + 1).toString().padLeft(2, '0');
        final safeName = _safeFileName(attachment.name);
        archive.add(
          ArchiveFile.bytes(
            'justificantes/$folder/${sequence}_$safeName',
            bytes,
          ),
        );
      }
    }

    archive.add(
      ArchiveFile.string(
        'RESUMEN_${quarter}T_$year.txt',
        _buildSummary(
          expenses: periodExpenses,
          year: year,
          quarter: quarter,
          attachmentCount: attachmentCount,
          withoutDigitalReceiptCount: withoutDigitalReceiptCount,
          missingStoredFiles: missingStoredFiles,
        ),
      ),
    );

    final zipBytes = Uint8List.fromList(
      ZipEncoder().encode(archive, level: DeflateLevel.bestSpeed),
    );
    return GestoriaExportPackage(
      fileName: 'RutaClara_gestoria_${quarter}T_$year.zip',
      bytes: zipBytes,
      expenseCount: periodExpenses.length,
      attachmentCount: attachmentCount,
      withoutDigitalReceiptCount: withoutDigitalReceiptCount,
    );
  }

  String _buildCsv(List<Expense> expenses) {
    const headers = [
      'Fecha',
      'Proveedor',
      'Concepto',
      'Categoría',
      'Importe total',
      'Base imponible',
      'IVA %',
      'IVA soportado',
      'IRPF %',
      'IRPF retenido',
      'Total pagado',
      'Deducible',
      'Base deducible',
      'IVA deducible',
      'Forma de pago',
      'Prorrateo (meses)',
      'Coste mensual',
      'Nº justificantes',
      'Justificantes',
      'Estado documental',
    ];
    final rows = <List<String>>[
      headers,
      ...expenses.map(
        (expense) => [
          fullDate(expense.date),
          expense.supplier,
          expense.description,
          expense.category.label,
          _decimal(expense.amount),
          _decimal(expense.baseAmount),
          _decimal(expense.vatRate),
          _decimal(expense.vatAmount),
          _decimal(expense.irpfRate),
          _decimal(expense.irpfAmount),
          _decimal(expense.payableAmount),
          expense.deductible ? 'Sí' : 'No',
          _decimal(expense.deductibleBase),
          _decimal(expense.deductibleVat),
          expense.paymentMethod,
          expense.prorationMonths.toString(),
          _decimal(expense.monthlyAmount),
          expense.attachments.length.toString(),
          expense.attachments.map((item) => item.name).join(' | '),
          expense.attachments.isEmpty
              ? 'Sin archivo digital'
              : 'Con justificante',
        ],
      ),
    ];

    return rows.map((row) => row.map(_csvCell).join(';')).join('\r\n');
  }

  String _buildSummary({
    required List<Expense> expenses,
    required int year,
    required int quarter,
    required int attachmentCount,
    required int withoutDigitalReceiptCount,
    required List<String> missingStoredFiles,
  }) {
    final total = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final deductibleBase = expenses.fold(
      0.0,
      (sum, item) => sum + item.deductibleBase,
    );
    final deductibleVat = expenses.fold(
      0.0,
      (sum, item) => sum + item.deductibleVat,
    );
    final withheldIrpf = expenses.fold(
      0.0,
      (sum, item) => sum + item.irpfAmount,
    );
    final buffer = StringBuffer()
      ..writeln('RUTACLARA - PAQUETE PARA GESTORÍA')
      ..writeln('Periodo: ${quarter}T $year')
      ..writeln('Generado: ${fullDate(DateTime.now())}')
      ..writeln()
      ..writeln('Gastos incluidos: ${expenses.length}')
      ..writeln('Importe total: ${euro(total)}')
      ..writeln('Base deducible: ${euro(deductibleBase)}')
      ..writeln('IVA soportado deducible: ${euro(deductibleVat)}')
      ..writeln('IRPF retenido: ${euro(withheldIrpf)}')
      ..writeln('Justificantes incluidos: $attachmentCount')
      ..writeln('Gastos sin justificante digital: $withoutDigitalReceiptCount')
      ..writeln()
      ..writeln('CONTENIDO')
      ..writeln('- CSV con el detalle de gastos, base, IVA e IRPF.')
      ..writeln('- Carpeta justificantes, ordenada por gasto.')
      ..writeln('- Este resumen de control.');

    if (missingStoredFiles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('ARCHIVOS NO ENCONTRADOS EN EL DISPOSITIVO');
      for (final file in missingStoredFiles) {
        buffer.writeln('- $file');
      }
    }

    buffer
      ..writeln()
      ..writeln(
        'Nota: las cifras son orientativas. La gestoría debe validar la deducibilidad y el periodo fiscal de cada documento.',
      );
    return buffer.toString();
  }

  String _expenseFolder(Expense expense) {
    final date =
        '${expense.date.year}-'
        '${expense.date.month.toString().padLeft(2, '0')}-'
        '${expense.date.day.toString().padLeft(2, '0')}';
    final reference = expense.id.length <= 6
        ? expense.id
        : expense.id.substring(expense.id.length - 6);
    return '${date}_${_safeFileName(expense.supplier)}_$reference';
  }

  String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) return 'documento';
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  String _decimal(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _csvCell(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}
