import 'dart:convert';
import 'dart:html' as html;
import 'backup_file.dart';

Future<String> saveBackup(String jsonString) async {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final timestamp =
      DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
  final fileName = 'ProCon_Backup_$timestamp.json';
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}

Future<List<BackupFile>> listBackups() async => [];

Future<String> readBackup(String id) async {
  throw UnsupportedError('Use the file picker to import backups on web.');
}

Future<String?> pickAndReadBackup() async {
  final input = html.FileUploadInputElement()..accept = '.json,application/json';
  input.click();
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final reader = html.FileReader();
  reader.readAsText(files[0]);
  await reader.onLoad.first;
  return reader.result as String;
}
