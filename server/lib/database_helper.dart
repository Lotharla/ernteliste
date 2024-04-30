import 'sqflite_helper.dart';
import 'tables.dart';

bool verbose = false;

class DatabaseHelper extends SqfliteHelper {
  static const _databaseVersion = 2;
  
  DatabaseHelper([String file = '']) {
    init(file);
  }

  Database? _db;
  bool multipart = false;
  bool get keep => databaseFile == inMemoryDatabasePath || multipart;
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
  }
  // this opens the database (and creates it if it doesn't exist)
  Future<Database?> open([bool empty = false]) async {
    if (_db != null && keep) return _db;
    String path = await databasePath();
    if (empty) {
      await deleteDatabase(path);
    }
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        var batch = db.batch();
        if (oldVersion == 1) {
          _updateTableErtragV1toV2(batch);
        }
        await batch.commit();
      },
    );
    if (verbose) print('open $path');
    return _db;
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUser (
        $columnName TEXT UNIQUE,
        $columnFunktion TEXT,
        $columnAktiv INTEGER NOT NULL CHECK ($columnAktiv IN (0,1))
      )
      ''');
    await db.execute('''
      INSERT INTO $tableUser ($columnName, $columnFunktion, $columnAktiv) VALUES ('dev', 'admin', 1)
      ''');
    await db.execute('''
      CREATE TABLE $tableKulturen (
        $columnArt TEXT,
        $columnSorte TEXT,
        $columnKuerzel TEXT,
        $columnAktiv INTEGER NOT NULL CHECK ($columnAktiv IN (0,1)),
        UNIQUE($columnArt,$columnSorte,$columnKuerzel)
      )
      ''');
    await db.execute('''
      CREATE TABLE $tableEinheiten (
        $columnArt TEXT UNIQUE
      )
      ''');
    await db.execute('''
      CREATE TABLE $tableErtrag (
        $columnKw TEXT,
        $columnKultur TEXT,
        $columnSatz INTEGER,
        $columnMenge REAL,
        $columnEinheit TEXT,
        $columnBemerkungen TEXT,
        $columnName TEXT
      )
      ''');
  }
  void _updateTableErtragV1toV2(Batch batch) {
    batch.execute('''
      ALTER TABLE $tableErtrag ADD COLUMN $columnSatz INTEGER
      ''');
  }

  Future<void> close({bool doit = false}) async {
    if (_db == null || (keep && !doit)) return;
    await _db!.close();
    _db = null;
    if (verbose) print('close db');
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> replace(Map<String, Object?> row, 
      {String table = tableErtrag,
       conflictAlgorithm = ConflictAlgorithm.replace}
  ) async {
    return await _db!.insert(table, row, conflictAlgorithm: conflictAlgorithm);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, Object?>>> queryAllRows({String table = tableErtrag}) async {
    return await _db!.query(table);
  }
  
  Future<List<Map<String, Object?>>> query(
    {String table = tableErtrag,
    bool? distinct,
    List<String>? projection,
    String? where,
    List<Object?>? whereArgs}
  ) async {
    return await _db!.query(
      table, 
      distinct: distinct, 
      columns: projection ?? [columnId, ...?columns[table]], 
      where: where, 
      whereArgs: whereArgs
    );
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
  int? firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        return int.tryParse(firstRow.values.first.toString());
      }
    }
    return null;
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryStats({String stat = 'count', String table = tableErtrag}) async {
    final results = await _db!.rawQuery('SELECT $stat($columnId) FROM $table');
    return firstIntValue(results) ?? 0;
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, Object?> row, {String table = tableErtrag}) async {
    int id = row[columnId] as int;
    return await _db!.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id, {String table = tableErtrag}) async {
    return await _db!.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  Future<int> deleteAllRows({String table = tableErtrag}) async {
    return await _db!.delete(table);
  }

  Batch batch() {
    return _db!.batch();
  }

  Future<List<int>> multiInsert(List<Map<String, Object?>> rows, {String table = tableErtrag}) async {
    List<int> ids = [];
    int id = await queryStats(stat: 'max', table: table);
    var batch = _db!.batch();
    for (var row in rows) {
      row[columnId] = ++id;
      batch.insert(table, row);
      ids.add(id);
    }
    batch.commit(noResult: true);
    return ids;
  }
}
