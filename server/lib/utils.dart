import 'dart:math';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:server/template_string.dart';
import 'package:week_of_year/week_of_year.dart';
import 'tables.dart';

String ellipsize(
  String text, {
  required int maxLength,
  bool showEllipsisCount = true,
}) {
  assert(maxLength > 0);

  final characters = Characters(text);

  if (characters.length <= maxLength) {
    return characters.string;
  }

  if (!showEllipsisCount) {
    // The final string result should not exceed maxLength, so we take into
    // take into account the added '…' character
    final end = maxLength - 1;
    return '${characters.getRange(0, end).string}…';
  }

  final shownTextLength =
      _calculateShownTextLength(characters.length, maxLength);

  // The number of characters hidden by the ellipsis.
  final ellipsisCount = characters.length - shownTextLength;

  return '${characters.getRange(0, shownTextLength).string}… (+$ellipsisCount)';
}
int _calculateShownTextLength(int initialTextLength, int maxLength) {
  assert(initialTextLength > maxLength);

  // The first approximation of the ellipsis count (which is the number of
  // characters from the initial text that will be hidden by the ellipsis.)
  final initialEllipsisCount = initialTextLength - maxLength;

  var previousEllipsisCount = initialEllipsisCount;

  // We first calculate the [shownTextLength] according to our approximation of
  // the ellipsis count. Then, we calculate the new ellipsis count.
  // - If the new ellipsis count has the same length as the previous one, it
  //   means that the [shownTextLength] will remain the same, and thus is
  //   accurate.
  // - If the new ellipsis count has a different length than the previous one ,
  //   it means that the [shownTextLength] will have to change, so we redo the
  //   calculations with the new values.
  while (true) {
    // This includes the extra characters : `… (+)` and the length of the
    // "ellipsis count"
    final extraCharactersCount = 5 + previousEllipsisCount.toString().length;

    final shownTextLength = max(maxLength - extraCharactersCount, 0);

    final newEllipsisCount = initialTextLength - shownTextLength;

    if (newEllipsisCount.toString().length ==
        previousEllipsisCount.toString().length) {
      return shownTextLength;
    }

    previousEllipsisCount = newEllipsisCount;
  }
}
Future<String> placeholderString(Random rnd) async {
  var uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/${1+rnd.nextInt(100)}');
  return jsonDecode(await http.read(uri))['title'];
}
Future<List<String>> loadStrings(String path) async {
  var file = File('../assets/$path');
  assert(await file.exists());
  return LineSplitter().convert(await file.readAsString());
}
Stream<List?> streamLinesFromFile(String path) async* {
  final file = File('../assets/$path');
  if (!await file.exists()) {
    yield null;
  }
  final stream = file.openRead()
    .transform(utf8.decoder)
    .transform(LineSplitter());
  await for (String row in stream) {
    yield row.split(',');
  }
}
dynamic trimCsvElement(String element) {
  element = element.trim();
  // var bval = bool.tryParse(element);
  // if (bval != null) return bval;
  // var ival = int.tryParse(element);
  // if (ival != null) return ival;
  // var dval = double.tryParse(element);
  // if (dval != null) return dval;
  if (element.startsWith('"') && element.endsWith('"')) {
      element = element.substring(1, element.length - 1);
  }
  if (element.startsWith("'") && element.endsWith("'")) {
      element = element.substring(1, element.length - 1);
  }
  return element;
}
Future<List<Map<String, dynamic>>> loadRecords(String? path,
  {Stream<List?> Function(String path) streamer = streamLinesFromFile,
  List<String> headers = const [],
  int columnAktivDefault = 0,
  num columnMengeDefault = 0.0}
) async {
  List<Map<String,dynamic>> records = [];
  if (path != null) {
    await for (List? line in streamer(path)) {
      if (line == null) {
        break;
      }
      if (headers.isEmpty) {
        headers = line.map((e) => e as String).toList();
        continue;
      }
      Map<String,dynamic> row = {};
      int i = 0;
      for (var hdr in headers) {
        dynamic value;
        switch (hdr) {
          case columnAktiv:
            value = i < line.length ? int.tryParse(trimCsvElement(line[i])) : columnAktivDefault;
            break;
          case columnMenge:
          case columnAnteile:
            value = i < line.length ? double.tryParse(trimCsvElement(line[i])): columnMengeDefault;
            break;
          default:
            value = i < line.length ? trimCsvElement(line[i]) : '';
        }
        row[hdr] = value;
        i++;
      }
      records.add(row);
    }
  }
  return records;
}
String queryParams(String key, List? lst) {
  String params = '';
  if (lst == null || lst.isEmpty) {
    return params;
  }
  for (var el in lst) { params += '&$key=$el'; }
  return params;
}
bool pathStartsWith(String path, String starter) => path.startsWith('$starter/');
DateTime refDay([int? year]) {
  if (year == null) {
    return DateTime.now();
  } else {
    return DateTime(year, 12, 28);
  }
}
String woyString(int woy) => NumberFormat("00").format(woy);
String weekOfYear({DateTime? now, int plus = 0}) {
  now = now ?? DateTime.now();
  DateTime today = now.add(Duration(days: 7 * plus));
  return '${today.year}-${woyString(today.weekOfYear)}';
} 
Future<Ertrag> randomErtrag(
    {String? kw, int? year, int? woy, 
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
    woy = int.parse(kw.substring(1+dash));
  } else {
    woy = woy ?? 1+rnd.nextInt(refDay(year).weekOfYear);
  }
  var menge = 1+rnd.nextInt(100);
  var anteile = 1+rnd.nextInt(10);
  var bemerkungen = testing ? '' : await placeholderString(rnd);
  var name = '';
  Ertrag ertrag = Ertrag(
    '$year-${woyString(woy)}', 
    kulturen[rnd.nextInt(kulturen.length)],
    1 + rnd.nextInt(9),
    menge, anteile,
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

String appHomePath() {
  const home = String.fromEnvironment('APP_HOME');
  // print('APP_HOME $home');
  if (home.isNotEmpty) {
    return home;
  } else {
    String path = Platform.script.toFilePath();
    if (extension(path) == '.dill') {
      path = Directory.current.toString();
      path = path.substring(1 + path.indexOf('\''), path.indexOf('ernteliste') + 10);
      return path;
    } else if (extension(path) == '.dart') {
      return path.substring(0, path.indexOf('ernteliste') + 10);
    } else {
      return dirname(dirname(dirname(path)));
    }
  }
}
Map<String,dynamic> interpolate(String jsonData, Map<String,dynamic> params) {
  Map<String,dynamic> data = jsonDecode(jsonData);
  data.forEach((key, value) {
    if (value is String) {
      data[key] = TemplateString(value).format(params);
    }
  });
  return data;
}
Future<dynamic> getConfig() async {
  var path = appHomePath();
  String configFilePath = join(path, 'assets/config.json');
  if (await File(configFilePath).exists()) {
    final params = <String, dynamic>{'appHome': path};
    return interpolate(await File(configFilePath).readAsString(), params);
  } else {
    final config = {
      'host': 'localhost', 
      'port': 8080, 
      'service': 'ertrag', 
      'database': join(path, 'data/ernteliste.db')};
    await File(configFilePath).writeAsString(jsonEncode(config));
    return config;
  }
}
Future<Process> runServer(String? path, {String port = '8080', String? database = '/tmp/test.db'}) async {
  var serverPath = path ?? Platform.script.toFilePath();
  // print('path of server: $serverPath');
  Process p = await Process.start(
    'dart', ['run', serverPath],
    environment: database == null ? {'PORT': port} : {'PORT': port, 'DATABASE': database},
  );
  // Wait for server to start and print to stdout.
  String element = String.fromCharCodes(await p.stdout.first);
  if (!element.startsWith(serverListening())) {
    await Future.delayed(Duration(seconds: 1));
  }
  return p;
}
String serverListening({String port = ''}) => 'Server listening on port $port';
Future<void> killServer({final port = '8080'}) async {
  await http.get(Uri.parse('http://localhost:$port/bye/bye'));
}