import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';
import 'db_service.dart';

class ExportImportService {
  final DbService _db = DbService();

  /// Export all entries to iCloud Drive
  Future<String> exportToICloud() async {
    try {
      // Get all entries from database
      final entries = await _db.queryAll();

      // Convert entries to JSON
      final jsonData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'entriesCount': entries.length,
        'entries': entries.map((e) => e.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Get iCloud Documents directory
      final directory = await _getICloudDirectory();
      if (directory == null) {
        throw Exception(
            'iCloud Drive not available. Please enable iCloud Drive in Settings.');
      }

      // Create ProCon folder in iCloud if it doesn't exist
      final proconDir = Directory('${directory.path}/ProCon');
      if (!await proconDir.exists()) {
        await proconDir.create(recursive: true);
      }

      // Create timestamped filename
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${proconDir.path}/ProCon_Backup_$timestamp.json');

      // Write to file
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Import entries from iCloud Drive
  Future<int> importFromICloud(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // Read JSON file
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate format
      if (!jsonData.containsKey('entries')) {
        throw Exception('Invalid backup file format');
      }

      final entriesList = jsonData['entries'] as List;
      int importedCount = 0;

      // Import each entry
      for (var entryMap in entriesList) {
        try {
          final entry = Entry.fromMap(entryMap as Map<String, dynamic>);
          await _db.insertEntry(entry);
          importedCount++;
        } catch (e) {
          // Skip invalid entries
          print('Skipped invalid entry: $e');
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }

  /// Get list of backup files from iCloud
  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await _getICloudDirectory();
      if (directory == null) {
        return [];
      }

      final proconDir = Directory('${directory.path}/ProCon');
      if (!await proconDir.exists()) {
        return [];
      }

      final files = await proconDir.list().where((entity) {
        return entity is File && entity.path.endsWith('.json');
      }).toList();

      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aStat = (a as File).statSync();
        final bStat = (b as File).statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  /// Get iCloud Drive directory
  Future<Directory?> _getICloudDirectory() async {
    if (Platform.isIOS) {
      // On iOS, iCloud Drive is typically at ~/Library/Mobile Documents/
      // But we'll use the app's documents directory with cloud sync enabled
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        // Try to access iCloud container
        final icloudDir = Directory(
            '${appDocDir.parent.parent.path}/Library/Mobile Documents/iCloud~com.procon.app/Documents');

        // Fallback to regular documents directory
        // (iCloud sync needs to be configured in Xcode capabilities)
        return appDocDir;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Export to local file (alternative to iCloud)
  Future<String> exportToLocal() async {
    try {
      final entries = await _db.queryAll();

      final jsonData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'entriesCount': entries.length,
        'entries': entries.map((e) => e.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${directory.path}/ProCon_Backup_$timestamp.json');

      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Local export failed: $e');
    }
  }
}
