// import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import 'package:server/database_helper.dart';
import 'package:server/tables.dart';

class DatabaseService extends DatabaseHelper {
  DatabaseService();
  factory DatabaseService.initialize({String file = ""}) {
    final instance = DatabaseService();
    if (file.isNotEmpty) instance.databaseFile = file;
    return instance;
  }
  Future<void> touch({bool? clear}) async {
    await open(clear ?? false);
    await close();
  }
  Future<DatabaseService> info() async {
    final db = await open(false);
    List<Map> vers = await db!.rawQuery('SELECT sqlite_version()');
    print(vers);
    await close();
    print('database: \'$databaseFile\'');
    return this;
  }
  String? whereClause(String key, List? vals) {
    if (vals == null || vals.isEmpty) {
      return null;
    }
    if (vals[0] is String) {
      vals = vals.map((e) => "'$e'").toList();
    }
    var where = vals.toString();
    where = where.substring(1, where.length - 1);
    return "$key in ($where)";
  }
  Future<dynamic> serve(String oper, 
      {String? where,
      List<int>? ids, 
      List<String>? kws, 
      List<String>? cols,
      String table = tableErtrag, 
      String json = ""}) async {
    final db = await open();
    dynamic res = [];
    try {
      switch (oper) {
        case 'exist':
          res = await db!.query('sqlite_master', where: 'name = ?', whereArgs: [table]);
          return jsonEncode(res.isNotEmpty);
        case 'setup':
          await db!.rawQuery('CREATE TABLE IF NOT EXISTS $table ($columnArt TEXT)');
          res = await queryMaxId(table: table);
          if (res == 0) {
            String data = jsonDecode(json).reduce((value, element) {
              var s = value.startsWith("('") ? value : "('$value')";
              return "$s,('$element')";
            });
            await db.rawQuery('INSERT INTO $table (art) VALUES $data');
            if (verbose) print('setup: $table');
            res = json;
          }
          break;
        case 'fetch':
          switch (table) {
          case 'sqlite_master':
            res = await db!.query('sqlite_master');
            break;
          case columnBemerkungen:
            final results = await db!.rawQuery(
              'SELECT DISTINCT $table FROM $tableErtrag ORDER BY $table COLLATE NOCASE ASC'
            );
            res = results.map((e) => e[columnBemerkungen]).toList();
            break;
          default:
            final results = await db!.rawQuery(
              'SELECT $columnArt FROM $table ORDER BY art COLLATE NOCASE ASC'
            );
            res = results.map((e) => e[columnArt]).toList();
          }
          break;
        case 'query':
          where = where ?? (
            kws != null ? whereClause(columnKw, kws) : whereClause(columnId, ids)
          );
          List<Map<String, Object?>> rows = await query(
            table: table,
            distinct: false,
            projection: cols,
            where: where,
          );
          res = rows;
          break;
        case 'insert':
          var maps = jsonDecode(json);
          if (maps is! List) {
            maps = [maps as Map<String, Object?>];
          } else {
            maps = maps.map((e) => e as Map<String, Object?>).toList();
          }
          final ids = await multiInsert(maps as List<Map<String, Object?>>, table: table);
          if (verbose) print('inserted row ids: $ids');
          res = ResponseModel(ids, 'inserted');
          break;
        case 'replace':
          var row = jsonDecode(json) as Map<String,Object?>;
          if (row.containsKey(columnId) && row[columnId] == null) row.remove(columnId);
          final id = await replace(row, table: table);
          if (verbose) print('replaced row id: $id');
          res = ResponseModel([id], row[columnId] == null ? 'inserted' : 'updated');
          break;
        case 'update':
          if (ids != null && ids.isNotEmpty) {
            var row = jsonDecode(json);
            List<int> idsAffected = [];
            for (int i in ids) {
              row[columnId] = i;
              var j = await update(row, table: table);
              if (j > 0) {
                idsAffected.add(i);
              }
            }
            if (verbose) print('updated ${idsAffected.length} row(s)');
            res = ResponseModel(idsAffected, 'updated');
          }
          break;
        case 'delete':
          if (ids != null && ids.isNotEmpty) {
            List<int> idsAffected = [];
            for (int i in ids) {
              var j = await delete(i, table: table);
              if (j > 0) {
                idsAffected.add(i);
              }
            }
            if (verbose)  print('deleted ${idsAffected.length} row(s)');
            res = ResponseModel(idsAffected, 'deleted');
          }
          break;
        case 'clear':
          if (table == tableErtrag) {
            int idsAffected = await deleteAllRows();
            if (verbose) print('deleted all row(s)');
            res = ResponseModel('all ($idsAffected)', 'deleted');
          } else {
            await db!.rawQuery('DROP TABLE IF EXISTS $table');
            if (verbose) print("table '$table' dropped");
          }
          break;
        default:
          throw Exception('illegal operation');
      }
      return jsonEncode(res);
    } 
    catch (ex) {
      print(ex.toString());
      return null;
    }
    finally {
      await close();
    }
  }
  Future<bool> isUser(String name, {String? funk}) async {
    final result = jsonDecode(await serve('query', 
      table: tableUser, 
      where: "$columnName = '$name' and $columnAktiv <> 0"));
    if (result.isEmpty) {
      return false;
    } else if (funk != null) {
      return result[0][columnFunktion] == funk;
    } else {
      return true;
    }
  }
}
class ResponseModel {
  final dynamic id;
  final String content;
  ResponseModel(this.id, this.content);
  Map<String, Object?> toJson() {
    return {
      columnId: id,
      'record': content
    };
  }
}
