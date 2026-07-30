import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'procon.db');
    _db = await openDatabase(path, version: 3, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE entries (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          pros TEXT,
          cons TEXT,
          notes TEXT,
          url TEXT,
          rawText TEXT,
          createdAt TEXT NOT NULL,
          latitude REAL,
          longitude REAL
        )
      ''');
      // Add indexes for optimized searches on large datasets
      await db
          .execute('CREATE INDEX idx_title ON entries(title COLLATE NOCASE)');
      await db.execute('CREATE INDEX idx_type ON entries(type)');
      await db.execute('CREATE INDEX idx_createdAt ON entries(createdAt DESC)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 3) {
        // Add rawText column if upgrading from older version
        try {
          await db.execute('ALTER TABLE entries ADD COLUMN rawText TEXT');
        } catch (e) {
          // Column might already exist, recreate table
          await db.execute('DROP TABLE IF EXISTS entries');
          await db.execute('''
            CREATE TABLE entries (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              type TEXT NOT NULL,
              pros TEXT,
              cons TEXT,
              notes TEXT,
              url TEXT,
              rawText TEXT,
              createdAt TEXT NOT NULL,
              latitude REAL,
              longitude REAL
            )
          ''');
        }
      }
    });
  }

  Future<int> insertEntry(Entry entry) async {
    return await _db!.insert('entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Entry>> queryAll() async {
    final maps = await _db!.query('entries', orderBy: 'createdAt DESC');
    return maps.map((map) => Entry.fromMap(map)).toList();
  }

  Future<List<Entry>> search(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    final maps = await _db!.query(
      'entries',
      where:
          'LOWER(title) LIKE ? OR LOWER(pros) LIKE ? OR LOWER(cons) LIKE ? OR LOWER(notes) LIKE ? OR LOWER(url) LIKE ?',
      whereArgs: List.filled(5, '%$normalizedQuery%'),
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Entry.fromMap(map)).toList();
  }

  Future<Entry?> findByTitle(String title) async {
    final normalizedTitle = title.toLowerCase().trim();
    final maps = await _db!.query(
      'entries',
      where: 'LOWER(title) = ?',
      whereArgs: [normalizedTitle],
      limit: 1,
    );
    return maps.isNotEmpty ? Entry.fromMap(maps.first) : null;
  }

  Future<List<Entry>> findByTitleContains(String title) async {
    final normalizedTitle = title.toLowerCase().trim();
    final maps = await _db!.query(
      'entries',
      where: 'LOWER(title) LIKE ?',
      whereArgs: ['%$normalizedTitle%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Entry.fromMap(map)).toList();
  }

  Future<void> deleteEntry(String id) async {
    await _db!.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEntry(Entry entry) async {
    return await _db!.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> close() async {
    await _db?.close();
  }
}
