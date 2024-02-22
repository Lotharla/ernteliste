import 'sqflite_helper.dart';
import 'tables.dart';

bool verbose = false;

class DatabaseHelper extends SqfliteHelper {
  static const _databaseVersion = 1;
  
  DatabaseHelper([String file = '']) {
    init(file);
  }

  // ignore: avoid_init_to_null
  Database? _db = null;
  
  bool get inMemory => databaseFile == inMemoryDatabasePath;

  // this opens the database (and creates it if it doesn't exist)
  Future<Database?> open([bool empty = false]) async {
    if (_db != null && inMemory) return _db;
    String path = await databasePath();
    if (empty) {
      await deleteDatabase(path);
    }
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
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
        $columnAktiv INTEGER NOT NULL
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
        $columnAktiv INTEGER,
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
        $columnMenge REAL,
        $columnEinheit TEXT,
        $columnBemerkungen TEXT,
        $columnName TEXT
      )
      ''');
  }

  Future<void> close() async {
    if (inMemory) return;
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
       conflictAlgorithm = ConflictAlgorithm.replace}) async {
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
    List<Object?>? whereArgs}) async {
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
  // raw SQL commands. This method uses a raw query to give the max id.
  Future<int> queryMaxId({String table = tableErtrag}) async {
    final results = await _db!.rawQuery('SELECT MAX($columnId) FROM $table');
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
    int id = await queryMaxId();
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
