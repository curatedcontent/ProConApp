import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_file.dart';

Future<String> saveBackup(String jsonString) async {
  final directory = await _getBackupDirectory();
  final timestamp =
      DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
  final file = File('${directory.path}/ProCon_Backup_$timestamp.json');
  await file.writeAsString(jsonString);
  return file.path;
}

Future<List<BackupFile>> listBackups() async {
  try {
    final directory = await _getBackupDirectory();
    final entities = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .toList();

    final backups = entities.map((entity) {
      final file = entity as File;
      final stat = file.statSync();
      return BackupFile(
        id: file.path,
        name: file.path.split(Platform.pathSeparator).last,
        modified: stat.modified,
      );
    }).toList();

    backups.sort((a, b) => b.modified.compareTo(a.modified));
    return backups;
  } catch (e) {
    return [];
  }
}

Future<String> readBackup(String id) async {
  final file = File(id);
  if (!await file.exists()) {
    throw Exception('File not found');
  }
  return file.readAsString();
}

Future<String?> pickAndReadBackup() async {
  throw UnsupportedError(
      'Pick-a-file import is only available on the web build; use the backup list instead.');
}

Future<Directory> _getBackupDirectory() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final proconDir = Directory('${appDocDir.path}/ProCon');
  if (!await proconDir.exists()) {
    await proconDir.create(recursive: true);
  }
  return proconDir;
}
