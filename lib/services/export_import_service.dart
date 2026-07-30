import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/entry.dart';
import 'backup_file.dart';
import 'db_service.dart';
import 'export_import_native.dart'
    if (dart.library.html) 'export_import_web.dart' as platform;

export 'backup_file.dart';

class ExportImportService {
  final DbService _db = DbService();

  bool get supportsBackupList => !kIsWeb;
  bool get supportsFilePicker => kIsWeb;

  /// Export all entries to a JSON backup (device storage on mobile/desktop,
  /// a browser download on web). Returns the file name/path of the backup.
  Future<String> exportToICloud() async {
    final jsonString = await _buildBackupJson();
    return platform.saveBackup(jsonString);
  }

  Future<String> exportToLocal() => exportToICloud();

  /// List previously saved backups. Not available on web (browsers can't
  /// list arbitrary local files) - use [importFromPicker] there instead.
  Future<List<BackupFile>> getBackupFiles() => platform.listBackups();

  /// Import entries from a backup previously returned by [getBackupFiles].
  Future<int> importFromICloud(String id) async {
    final jsonString = await platform.readBackup(id);
    return _importJson(jsonString);
  }

  /// Import entries by letting the user pick a backup file (web only).
  Future<int> importFromPicker() async {
    final jsonString = await platform.pickAndReadBackup();
    if (jsonString == null) return 0;
    return _importJson(jsonString);
  }

  Future<String> _buildBackupJson() async {
    final entries = await _db.queryAll();
    final jsonData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'entriesCount': entries.length,
      'entries': entries.map((e) => e.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  Future<int> _importJson(String jsonString) async {
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    if (!jsonData.containsKey('entries')) {
      throw Exception('Invalid backup file format');
    }

    final entriesList = jsonData['entries'] as List;
    int importedCount = 0;

    for (var entryMap in entriesList) {
      try {
        final entry = Entry.fromMap(entryMap as Map<String, dynamic>);
        await _db.insertEntry(entry);
        importedCount++;
      } catch (e) {
        // Skip invalid entries
      }
    }

    return importedCount;
  }
}
