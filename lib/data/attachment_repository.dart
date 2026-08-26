import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

class AttachmentRepository {
  static const _boxName = 'ruta_clara_attachments_v1';
  static Future<void>? _initialization;

  Future<Box<dynamic>> _openBox() async {
    _initialization ??= Hive.initFlutter();
    await _initialization;
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<void> saveAll(Map<String, Uint8List> attachments) async {
    if (attachments.isEmpty) return;
    final box = await _openBox();
    await box.putAll(attachments);
  }

  Future<Uint8List?> load(String id) async {
    final box = await _openBox();
    final value = box.get(id);
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    final keys = ids.toList();
    if (keys.isEmpty) return;
    final box = await _openBox();
    await box.deleteAll(keys);
  }
}
