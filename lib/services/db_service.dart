import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import '../models/entry.dart';

/// Local storage is always the source of truth for the UI - every read/write
/// goes through Sembast first so the app works fully offline. When a user is
/// signed in, writes are also mirrored to Firestore (fire-and-forget, so a
/// slow/offline network never blocks the local save), and [syncFromCloud]
/// does a one-time merge of local <-> cloud entries right after sign-in.
class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;
  final _store = StoreRef<String, Map<String, dynamic>>('entries');

  // Kept in sync with the store so callers that need a synchronous answer
  // (e.g. the browser's beforeunload handler) can check it without awaiting.
  bool _hasEntriesCache = false;
  bool get hasLocalEntriesSync => _hasEntriesCache;

  Future<void> init() async {
    if (_db != null) return;
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('procon.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, 'procon.db');
      _db = await databaseFactoryIo.openDatabase(path);
    }
    _hasEntriesCache = await hasLocalEntries();
  }

  CollectionReference<Map<String, dynamic>>? get _cloudCollection {
    // Cloud sync is currently only wired up on web (see main.dart) - on
    // other platforms Firebase is never initialized, so touching
    // FirebaseAuth.instance here would throw.
    if (!kIsWeb) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries');
  }

  void _mirrorToCloud(Entry entry) {
    _cloudCollection?.doc(entry.id).set(entry.toMap());
  }

  void _mirrorDeleteToCloud(String id) {
    _cloudCollection?.doc(id).delete();
  }

  /// Merges local and cloud entries after sign-in: entries missing locally
  /// are pulled down, entries missing in the cloud are pushed up. Entries
  /// that exist in both are left as-is (no conflict resolution for
  /// concurrent edits across devices in this pass).
  Future<void> syncFromCloud() async {
    final col = _cloudCollection;
    if (col == null) return;

    final snapshot = await col.get();
    final cloudIds = <String>{};
    for (final doc in snapshot.docs) {
      cloudIds.add(doc.id);
      final existsLocally = await _store.record(doc.id).get(_db!);
      if (existsLocally == null) {
        await _store.record(doc.id).put(_db!, doc.data());
      }
    }

    final localEntries = await queryAll();
    for (final entry in localEntries) {
      if (!cloudIds.contains(entry.id)) {
        _mirrorToCloud(entry);
      }
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
    _hasEntriesCache = true;
    _mirrorToCloud(entry);
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
    _hasEntriesCache = await hasLocalEntries();
    _mirrorDeleteToCloud(id);
  }

  Future<int> updateEntry(Entry entry) async {
    await _store.record(entry.id).put(_db!, entry.toMap());
    _mirrorToCloud(entry);
    return 1;
  }

  /// Whether there's any local data that only lives on this device (i.e.
  /// the user isn't signed in, so it isn't backed up anywhere else yet).
  Future<bool> hasLocalEntries() async {
    final key = await _store.findKey(_db!);
    return key != null;
  }

  Future<void> close() async {
    await _db?.close();
  }
}
