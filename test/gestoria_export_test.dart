import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_clara/data/attachment_repository.dart';
import 'package:ruta_clara/models/expense.dart';
import 'package:ruta_clara/models/expense_attachment.dart';
import 'package:ruta_clara/services/gestoria_export_service.dart';

class _MemoryAttachmentRepository extends AttachmentRepository {
  _MemoryAttachmentRepository(this.files);

  final Map<String, Uint8List> files;

  @override
  Future<Uint8List?> load(String id) async => files[id];
}

void main() {
  test('crea un ZIP trimestral con CSV, resumen y justificantes', () async {
    final invoiceBytes = Uint8List.fromList(utf8.encode('PDF de prueba'));
    final repository = _MemoryAttachmentRepository({'invoice-1': invoiceBytes});
    final expense = Expense(
      id: 'expense-123456',
      description: 'Repostaje',
      supplier: 'Estación Norte',
      amount: 121,
      date: DateTime(2026, 8, 14),
      category: ExpenseCategory.fuel,
      vatRate: 21,
      deductible: true,
      paymentMethod: 'Tarjeta',
      attachments: const [
        ExpenseAttachment(
          id: 'invoice-1',
          name: 'factura agosto.pdf',
          mimeType: 'application/pdf',
          size: 13,
        ),
      ],
    );

    final package = await GestoriaExportService(
      repository,
    ).buildQuarterPackage(expenses: [expense], year: 2026, quarter: 3);
    final archive = ZipDecoder().decodeBytes(package.bytes);
    final csv = archive.find('gastos_3T_2026.csv');
    final summary = archive.find('RESUMEN_3T_2026.txt');
    final invoice = archive.files.where(
      (file) => file.name.endsWith('01_factura_agosto.pdf'),
    );

    expect(package.fileName, 'RutaClara_gestoria_3T_2026.zip');
    expect(package.expenseCount, 1);
    expect(package.attachmentCount, 1);
    expect(csv, isNotNull);
    expect(utf8.decode(csv!.content), contains('Estación Norte'));
    expect(utf8.decode(csv.content), contains('121,00'));
    expect(summary, isNotNull);
    expect(invoice, hasLength(1));
    expect(invoice.single.content, invoiceBytes);
  });
}
