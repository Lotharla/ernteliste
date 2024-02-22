import 'dart:math';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:week_of_year/week_of_year.dart';
import 'tables.dart';

Future<String> placeholderString(Random rnd) async {
  var uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/${1+rnd.nextInt(100)}');
  return jsonDecode(await http.read(uri))['title'];
}
Future<List<String>> loadStrings(String name) async {
  var file = File('../assets/$name');
  assert(await file.exists());
  return LineSplitter().convert(await file.readAsString());
}
String queryParams(String key, List? lst) {
  String params = '';
  if (lst == null || lst.isEmpty) {
    return params;
  }
  for (var el in lst) { params += '&$key=$el'; }
  return params;
}
DateTime refDay([int? year]) {
  if (year == null || year == DateTime.now().year) {
    return DateTime.now();
  } else {
    return DateTime(year, 12, 28);
  }
}
String weekOfYear() {
  DateTime today = DateTime.now();
  return '${today.year}-${today.weekOfYear}';
} 
Future<Ertrag> randomErtrag(
    {String? kw, int? year, int? weekOfYear, 
    List? einheiten, List? kulturen, 
    bool testing = false}) async
{
  einheiten = einheiten ?? await loadStrings('einheiten.txt');
  kulturen = kulturen ?? await loadStrings('kulturen.txt');
  var now = DateTime.now();
  var rnd = Random(now.millisecondsSinceEpoch);
  year = year ?? now.year;
  kw = kw ?? '';
  int dash = kw.indexOf(r'-');
  if (dash >= 0) {
    year = int.parse(kw.substring(0, dash));
    weekOfYear = int.parse(kw.substring(1+dash));
  } else {
    var day = year == now.year ? now : refDay(year);
    weekOfYear = weekOfYear ?? 1+rnd.nextInt(day.weekOfYear);
  }
  var menge = 1+rnd.nextInt(100);
  var bemerkungen = testing ? '' : await placeholderString(rnd);
  var name = '';
  Ertrag ertrag = Ertrag(
    '$year-$weekOfYear', 
    kulturen[rnd.nextInt(kulturen.length)], 
    menge, 
    einheiten[rnd.nextInt(einheiten.length)], 
    bemerkungen,
    name
  );
  return ertrag;
}
RegExp kwRegExp() => RegExp(r'\d{4}-\d{1,2}');
String kwString(kw) => 'Kw $kw';
Map<String, List<int>> ertragMap(List<Map<String, dynamic>> records) {
  Map<String, List<int>> kwIds = {};
  for (var rec in records) {
    var kw = rec[columnKw];
    var id = rec[columnId];
    kwIds[kw] = kwIds.containsKey(kw) ? [id, ...?kwIds[kw]] : [id];
  }
  return kwIds;
}

Future<Process> runServer({final port = '8080', String database = '/tmp/test.db'}) async {
  Process p = await Process.start(
    'dart', ['run', '${Platform.environment['HOME']}/devel/ernteliste/server/bin/server.dart'],
    environment: {'PORT': port, 'DATABASE': database},
  );
  // Wait for server to start and print to stdout.
  await p.stdout.first;
  return p;
}
Future<void> killServer({final port = '8080'}) async {
  try {
    await http.get(Uri.parse('http://localhost:$port/bye/bye'));
  } catch (e) {
    print(e);
  }
}