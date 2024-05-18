import 'dart:io';
import 'dart:convert';

import 'package:date_checker/date_checker.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:server/tables.dart';
import 'package:server/database_service.dart';
import 'package:server/utils.dart';
import 'package:week_of_year/week_of_year.dart';

final port = '8080';
final url = 'http://localhost:$port';
final database = '/tmp/test.db';

DatabaseService dbService = DatabaseService.initialize(file: database);

int noCase(a, b) => a.toLowerCase().compareTo(b.toLowerCase());

num? timeoutFactor = 10;
void main() {
  Process? p;
  setUp(() async {
    // File(database).createSync(recursive: true);
    try {
      final config = await getConfig();
      p = await runServer(config['server'],
        port: port, 
        database: database,
      );
    } on Exception catch (e) {
      print(e);
    }
  });
  tearDown(() => p?.kill());

  test('Database', () async {
    await checkDatabase();
  }, timeout: Timeout.factor(timeoutFactor));
  test('404 bye', () async {
    var response = await http.get(Uri.parse('$url/foobar'));
    expect(response.statusCode, 404);
    expect(() async {
      await http.get(Uri.parse('$url/bye/bye'));
    }, throwsException);
  });
  test('Setup Einheiten', () async {
    await dbService.serve('clear', table: tableEinheiten);
    expect(await dbService.isEmpty(tableEinheiten), true);
    var records = await loadRecords('einheiten.txt', 
      headers: columns[tableEinheiten]!);
    var result = await dbService.serve('Setup', 
      table: tableEinheiten, 
      json: jsonEncode(records));
    expect(jsonDecode(result), isA<Map>());
    expect(await dbService.isEmpty(tableEinheiten), false);
    result = await checkFetch(tableEinheiten);
    List<String> data = await loadStrings('einheiten.txt');
    data.sort(noCase);
    expect(result, data);
  }, timeout: Timeout.factor(timeoutFactor));
  test('Setup Kulturen', () async {
    await dbService.serve('clear', table: tableKulturen);
    expect(await dbService.isEmpty(tableKulturen), true);
    var records1 = await loadRecords('Art_Sorte_Kuerzel.csv', 
      headers: columns[tableKulturen]!, 
      columnAktivDefault: 1);
    var records2 = await loadRecords('kulturen.txt', 
      headers: columns[tableKulturen]!, 
      columnAktivDefault: 0);
    var result = await dbService.serve('Setup', 
      table: tableKulturen, 
      json: jsonEncode([...records1, ...records2]));
    expect(jsonDecode(result), isA<Map>());
    expect(await dbService.isEmpty(tableKulturen), false);
    List results = await checkFetch(tableKulturen, where: rowAktiv());
    for (var res in results) {
      (res as Map).remove(columnId);
    }
    expect(results, records1);
  }, timeout: Timeout.factor(timeoutFactor));
  test('einheiten kulturen', () async {
    await checkDrop(tableEinheiten);
    expect(await checkExists(tableEinheiten),false);
    var data = await checkSetup(tableEinheiten);
    expect(await checkExists(tableEinheiten),true);
    data.sort(noCase);
    var result = await checkFetch(tableEinheiten);
    expect(result, data);
    await checkDrop(tableEinheiten);
    await checkDrop(tableKulturen);
    expect(await checkExists(tableKulturen),false);
    data = await checkSetup(tableKulturen);
    expect(await checkExists(tableKulturen),true);
    data.sort(noCase);
    result = await checkFetch(tableKulturen);
    expect(result, data);
    await checkDrop(tableKulturen);
  }, timeout: Timeout.factor(timeoutFactor), skip: true);
  test('user', () async {
    await dbService.serve('clear', table: tableUser);
    expect(await dbService.isEmpty(tableUser), true);
    var users = [];
    for (var i = 0; i < 2; i++) {
      await dbService.serve('Setup', table: tableUser);
      var response = await http.get(Uri.parse('$url/user?'));
      expect(response.body, isNotNull);
      users = jsonDecode(response.body);
      expect(users, isList);
      expect(users.length, setupUser.length);
    }
    var results = users.where((rec) {
      if (rec[columnName] == 'sys') {
        var einstellungen = jsonDecode(rec[columnEinst]);
        expect(einstellungen, isMap);
        expect(einstellungen['Anteile'], 1);
        return true;
      }
      return false;
    });
    expect(results.length, 1);
    bool ok = await dbService.isUser('dev', funk: 'admin');
    expect(await checkWho('dev', funk: 'admin'), ok);
    expect(await dbService.isUser('div', funk: 'admin'), false);
    expect(await dbService.isUser('dev', funk: 'user'), false);
    expect(await dbService.isUser('dev'), true);
    expect(await checkWho('sys'), false);
  }, timeout: Timeout.factor(timeoutFactor));
  test('bemerkungen', () async {
    await dbService.serve('clear');
    int cnt = 30;
    var data = await randomData(cnt);
    List ids = await checkInsert(jsonEncode(data));
    expect(ids.length, cnt);
    var result = await checkFetch(columnBemerkungen);
    expect(cnt-result.length+1, isPositive);
  }, timeout: Timeout.factor(timeoutFactor), skip: true);
  test('ertrag kw', () async {
    await dbService.serve('clear');
    List records = await checkQuery();
    var now = DateTime.now();
    int cnt = 10;
    var len = records.length;
    if (len < cnt) {
      var data = [for (int i=len; i<cnt; i++) (await randomErtrag(year: now.year-i+len)).record];
      await checkInsert(jsonEncode(data));
    }
    records = await checkQuery(column: '["$columnId", "$columnKw"]');
    Map<String, List<int>> kwIds = ertragMap(records.map((e) => e as Map<String, dynamic>).toList());
    var allMatches = kwRegExp().allMatches(kwIds.toString());
    // print(kwIds);
    // for (var m in allMatches) {
    //     print('${m.start} ... ${m.end}');    
    // }
    expect(allMatches.length, equals(kwIds.length));
    for (var kw in kwIds.keys) {
      List kwRecs = await checkQuery(kw: kw);
      expect(kwRecs.length, kwIds[kw]?.length);
    }
    List recIds = kwIds.isEmpty ? [] : kwIds.values.reduce((value, element) => value + element);
    // print(recIds);
    expect(recIds.length, records.length);
  }, timeout: Timeout.factor(timeoutFactor));
  test('ertrag replace', () async {
    int cnt = 4;
    var data = await randomData(cnt);
    var results = jsonDecode(await dbService.serve('query'));
    int len = results.length;
    for (int i=0; i<cnt; i++) {
      var result = await dbService.serve('upsert', json: jsonEncode(data[i]));
      expect(result, isNotNull);
      data[i][columnId] = jsonDecode(result)[columnId].first;
    }
    results = jsonDecode(await dbService.serve('query'));
    expect(results.length, len + cnt);
    var id = data[0][columnId];
    for (int i=0; i<cnt-1; i++) {
      data[i][columnId] = data[i+1][columnId];
    }
    data[cnt-1][columnId] = id;
    for (int i=0; i<cnt; i++) {
      var result = await dbService.serve('upsert', json: jsonEncode(data[i]));
      expect(result, isNotNull);
    }
    results = jsonDecode(await dbService.serve('query'));
    expect(results.length, len + cnt);
    len = results.length;
    for (int i=0; i<cnt; i++) {
      var result = results[len-cnt+i];
      (result as Map).remove(columnId);
      var dat = data[(cnt+i-1)%cnt];
      dat.remove(columnId);
      expect(result, dat);
    }
    await dbService.serve('clear');
  }, timeout: Timeout.factor(timeoutFactor));
  test('ertrag CRUD', () async {
    int cnt = 3;
    var data = await randomData(cnt);
    List ids = await checkInsert(jsonEncode(data));
    List records = await checkQuery();
    List recIds = records.map((e) => e[columnId]).toList();
    int i = 0;
    for (var id in ids) {
      expect(recIds.contains(id), true);
      List idsAffected = await checkUpdate(id, '{"Kultur":"Tomate"}');
      expect(idsAffected.contains(id), true);
      records = await checkQuery(id: id);
      expect(jsonEncode(records), contains('Tomate'));
      idsAffected = await checkDelete(id);
      expect(idsAffected.contains(id), true);
      records = await checkQuery(id: id);
      expect(records, isEmpty);
      i++;
    }
    expect(i, cnt);
  }, timeout: Timeout.factor(timeoutFactor));
  test('ertrag fill', () async {
    await dbService.serve('clear');
    var today = DateTime.now();
    var kw0 = '${today.year}-00';
    expect(await checkQuery(kw: kw0), []);
    int cnt = 5;
    List data = await randomData(cnt, kw: kw0);
    // print(data);
    List ids = await checkInsert(jsonEncode(data));
    var results = await checkQuery(kw: kw0);
    expect(results.length, ids.length);
    // print(results);
    for (int i=0; i<cnt; i++) {
      var j = results[cnt-1-i][columnId];
      final result = Map.from(results[i]);
      result[columnId] = j;
      var id = await checkUpsert(jsonEncode(result));
      expect(id[0], j);
    }
    // print(results);
    for (var id in ids) {
      await checkDelete(id);
    }
    results = await checkQuery();
    var id = await checkUpsert(jsonEncode(data[0]));
    expect((await checkQuery()).length, results.length + 1);
    await checkDelete(id[0]);
    expect(await checkQuery(kw: kw0), []);
  }, timeout: Timeout.factor(timeoutFactor));
  test('DateTime.weekOfYear', () {
    final today = DateTime.now();
    print(today.weekOfYear); // Get the iso week of year
    print(today.ordinalDate); // Get the ordinal today
    print(today.isLeapYear); // Is this a leap year?
    print(DateFormat("y-MM-dd").format(today));

    final DateTime dateFromWeekNumber = dateTimeFromWeekNumber(today.year, today.weekOfYear, today.weekday);
    expect(
      DateFormat("yyyy-MM-dd").format(dateFromWeekNumber), 
      DateFormat("yyyy-MM-dd").format(today));

    print('weekStart : ${weekStart(date: today)}');
    print('weekEnd : ${weekEnd(date: today)}');
    print('weekOfYear 01/04 : ${DateTime(today.year, 1, 4).weekOfYear}');
    print('weekOfYear 12/28 : ${DateTime(today.year, 12, 28).weekOfYear}');
    var dateTime = DateTime(2020, 12, 28);
    expect(dateTime.weekOfYear, 53);
    var add = dateTime.add(const Duration(days: 4));
    expect(add.weekOfYear, 53);
  });
  test('reset', () async {
    await checkReset();
  }, timeout: Timeout.factor(timeoutFactor), skip: true);
}

Future<List<Map<String, Object?>>> randomData(int cnt, {String? kw}) async => 
  [for (int i=0; i<cnt; i++) (await randomErtrag(kw: kw)).record];

Future<dynamic> checkDatabase() async {
  var response = await http.get(Uri.parse(url));
  expect(response.statusCode, 200);
  expect(await File(response.body).exists(), true);
  expect(response.body, database);
  expect(dbService.flutterTest(), false);
  var master = await dbService.serve('fetch', table: 'sqlite_master');
  response = await http.get(Uri.parse('$url/sqlite_master'));
  expect(response.body, master);
}
Future<dynamic> checkReset() async {
  DateTime fileTime1 = await File(database).lastModified();
  print(fileTime1);
  var response = await http.post(Uri.parse('$url/reset'));
  expect(response.statusCode, 200);
  expect(await File(response.body).exists(), true);
  DateTime fileTime2 = await File(response.body).lastModified();
  print(fileTime2);
  expect(fileTime1.compareTo(fileTime2), -1);
}
Future<dynamic> checkWho(String name, {String? funk}) async {
  var response = await http.get(Uri.parse('$url/user?$columnName=$name&$columnFunktion=$funk'));
  expect(response.statusCode, 200);
  return jsonDecode(response.body);
}
Future<dynamic> checkExists(String table) async {
  final response = await http.head(Uri.parse('$url/${table.toLowerCase()}'));
  expect(response.statusCode, 200);
  expect(response.headers.containsKey('x_check_table'), true);
  return bool.parse(response.headers['x_check_table']!);
}
Future<dynamic> checkDrop(String table) async {
  expect(
    await http.head(Uri.parse('$url/${table.toLowerCase()}'), headers: {'X_CLEAR_TABLE': 'true'}), 
    isA<http.Response>());
}
Future<List> checkInsert(String data) async {
  final response = await http.post(
    Uri.parse('$url/ertrag'),
    headers: {'Content-Type': 'application/json'},
    body: data,
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotEmpty);
  return jsonDecode(response.body)[columnId];
}
Future<List> checkUpsert(String data) async {
  final response = await http.patch(
    Uri.parse('$url/ertrag'),
    headers: {'Content-Type': 'application/json'},
    body: data,
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotEmpty);
  return jsonDecode(response.body)[columnId];
}
Future<List> checkUpdate(int id, String data) async {
  final response = await http.put(
    Uri.parse('$url/ertrag?id=$id'),
    headers: {'Content-Type': 'application/json'},
    body: data,
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotNull);
  return jsonDecode(response.body)[columnId];
}
Future<List> checkDelete(int id) async {
  final response = await http.delete(
    Uri.parse('$url/ertrag?id=$id'),
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotNull);
  return jsonDecode(response.body)[columnId];
}
Future<List> checkQuery({int? id, String? kw, String? column}) async {
  var query = kw != null ? 'kw=$kw' : (id != null ? 'id=$id' : '');
  if (column != null) {
    query += '&column=$column';
  }
  final response = await http.get(
    Uri.parse('$url/ertrag?$query'),
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotNull);
  var records = jsonDecode(response.body);
  expect(records, isList);
  for (var rec in records) {
    expect(rec, isMap);
  }
  return records as List;
}
Future<List> checkFetch(String table, {String where = ''}) async {
  dynamic response;
  if (where.isEmpty) {
    if (table != columnBemerkungen) table = table.toLowerCase();
    response = await http.get(
      Uri.parse('$url/$table'),
    );
  } else {
    response = await http.get(
      Uri.parse('$url/table/$table?where=$where'),
    );
  }
  expect(response.statusCode, 200);
  expect(response.body, isNotNull);
  var records = jsonDecode(response.body);
  expect(records, isList);
  return records as List;
}
Future<List> checkSetup(String table) async {
  table = table.toLowerCase();
  List<String> data = await loadStrings('$table.txt');
  final response = await http.post(
    Uri.parse('$url/$table'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  expect(response.statusCode, 200);
  expect(response.body, isNotNull);
  var records = jsonDecode(response.body);
  expect(jsonDecode(records), isList);
  return data;
}
