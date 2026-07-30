import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import '../models/entry.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;
  final _store = StoreRef<String, Map<String, dynamic>>('entries');

  Future<void> init() async {
    if (_db != null) return;
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('procon.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, 'procon.db');
      _db = await databaseFactoryIo.openDatabase(path);
    }
  }

  bool _matches(Map<String, dynamic> value, String normalizedQuery) {
    bool contains(dynamic field) =>
        (field as String?)?.toLowerCase().contains(normalizedQuery) ?? false;
    return contains(value['title']) ||
        contains(value['pros']) ||
        contains(value['cons']) ||
        contains(value['notes']) ||
        contains(value['url']);
  }

  Future<int> insertEntry(Entry entry) async {
    await _store.record(entry.id).put(_db!, entry.toMap());
    return 1;
  }

  Future<List<Entry>> queryAll() async {
    final finder = Finder(sortOrders: [SortOrder('createdAt', false)]);
    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => Entry.fromMap(r.value)).toList();
  }

  Future<List<Entry>> search(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    final finder = Finder(
      filter: Filter.custom(
          (record) => _matches(record.value as Map<String, dynamic>, normalizedQuery)),
      sortOrders: [SortOrder('createdAt', false)],
    );
    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => Entry.fromMap(r.value)).toList();
  }

  Future<Entry?> findByTitle(String title) async {
    final normalizedTitle = title.toLowerCase().trim();
    final finder = Finder(
      filter: Filter.custom((record) =>
          ((record.value as Map<String, dynamic>)['title'] as String)
              .toLowerCase() ==
          normalizedTitle),
      limit: 1,
    );
    final records = await _store.find(_db!, finder: finder);
    return records.isNotEmpty ? Entry.fromMap(records.first.value) : null;
  }

  Future<List<Entry>> findByTitleContains(String title) async {
    final normalizedTitle = title.toLowerCase().trim();
    final finder = Finder(
      filter: Filter.custom((record) =>
          ((record.value as Map<String, dynamic>)['title'] as String)
              .toLowerCase()
              .contains(normalizedTitle)),
      sortOrders: [SortOrder('createdAt', false)],
    );
    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => Entry.fromMap(r.value)).toList();
  }

  Future<void> deleteEntry(String id) async {
    await _store.record(id).delete(_db!);
  }

  Future<int> updateEntry(Entry entry) async {
    await _store.record(entry.id).put(_db!, entry.toMap());
    return 1;
  }

  Future<void> close() async {
    await _db?.close();
  }
}
