import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:server/tables.dart';
import 'package:server/utils.dart';
import 'package:server/database_service.dart';
import 'package:ernteliste/src/app_constant.dart';

DatabaseService dbService = DatabaseService.initialize();
bool flutterTest() => dbService.flutterTest();

String? mess;
void message(String msg) {
  BuildContext? context = AppConstant.globalScaffoldKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    mess = null;
  } else {
    mess = msg;
  }
}
Future<Map<String, dynamic>> loadConfig() async {
  String data = await rootBundle.loadString("assets/config.json");
  return jsonDecode(data);
}
Future<void> setDatabase() async {
  final config = await loadConfig();
  if (config['database'] != null) {
    if (!kIsWeb && !flutterTest()) {
      dbService.databaseFile = config['database'];
    }
  }
  if (kIsWeb) {
    await Persistor.perform('server');
    if (!Persistor.serverAvailable) {
      message('Keine Persistenz der Daten...\nServer starten und neu anmelden!');
    }
  }
}
Future<List<String>> getStrings(String name) async {
  String data = await rootBundle.loadString("assets/$name");
  return const LineSplitter().convert(data);
}
Future<void> setupTables() async {
  for (String table in [tableKulturen, tableEinheiten]) {
    await Persistor.perform('setup',
      path: table,
      data: await getStrings('${table.toLowerCase()}.txt'),
    );
  }
}

Future<bool> exist(table) async => await Persistor.perform('exist', path: table) as bool;
String tableName(String path) => path.substring(path.indexOf('/')+1);
String tablePath(String table) => 'table/$table';

class Persistor {
  Persistor._();
  static Future<String> serviceUrl(String? path) async {
    final config = await loadConfig();
    path = path ?? config['service'];
    return 'http://${config['host']}:${config['port']}/$path';
  }
  static bool userAdmin = false;
  static bool serverAvailable = false;
  static Future<dynamic> perform(String oper, 
      {List<int>? ids, 
      List<String>? kws, 
      List<String>? cols, 
      String path = tableErtrag, 
      Object? data}) async {
    if (serverAvailable || serverOnly(oper)) {
      var url = await serviceUrl(
        serverOnly(oper) ? '' 
        : oper == 'who' ? 'user' 
        : path.contains('/') ? path
        : path.toLowerCase()
      );
      var client = http.Client(); 
      try {
        Uri uri;
        if (serverOnly(oper)) {
          uri = Uri.parse(oper == 'bye' ? '${url}bye/bye' : url);
        } else {
          String params;
          if (oper == 'who') {
            data = data as Map;
            params = 'who=${data[columnName]}&funk=${data[columnFunktion]}';
          } else {
            params = queryParams(columnId, ids);
            params += queryParams(columnKw, kws);
            params += queryParams('column', cols);
          }
          uri = Uri.parse('$url?$params');
        }
        final headers = {"content-type": "application/json"};
        http.Response response;
        switch (oper) {
          case 'bye':
            response = await http.get(uri);
            return response.body;
          case 'who':
            response = await http.get(uri);
            return response.body;
          case 'server':
            serverAvailable = false;
            response = await client.get(uri);
            serverAvailable = statusOK(response) && response.body.isNotEmpty;
            return response.body;
          case 'exist':
            response = await client.head(uri);
            return response.headers['x_check_table'] == 'true';
          case 'clear':
            response = await client.head(uri, headers: {'X_DROP_TABLE': 'true'});
            return null;
          case 'setup':
            response = await client.post(uri, headers: headers, body: jsonEncode(data));
            break;
          case 'fetch':
          case 'query':
            response = await client.get(uri);
            break;
          case 'insert':
            response = await client.post(uri, headers: headers, body: jsonEncode(data));
            break;
          case 'replace':
            response = await client.patch(uri, headers: headers, body: jsonEncode(data));
            break;
          case 'update':
            response = await client.put(uri, headers: headers, body: jsonEncode(data));
            break;
          case 'delete':
            response = await client.delete(uri);
            break;
          default:
            debugPrint(uri.toString());
            debugPrint(await http.read(uri));
            throw Exception('illegal request');
        }
        if (statusOK(response)) {
          return _result(oper, path, response.body);
        } else {
          throw Exception('response status code : ${response.statusCode }');
        }
      } 
      catch (ex) {
        debugPrint(ex.toString());
        return null;
      }
      finally { 
        client.close(); 
      }
    } else if (oper == 'who') {
      data = data as Map;
      var res = await dbService.isUser(
        data[columnName], 
        funk: data[columnFunktion]
      );
      return _result(oper, path, jsonEncode(res));
    } else {
      var res = await dbService.serve(oper, 
        ids: ids, 
        kws: kws, 
        cols: cols, 
        json: data != null ? jsonEncode(data) : "",
        table: tableName(path)
      );
      return _result(oper, path, res);
    }
  }

  static bool serverOnly(String oper) => ['server', 'bye'].contains(oper);
  static bool statusOK(http.Response response) => response.statusCode >= 200 && response.statusCode < 400;
  static Object? _result(String oper, String table, String res) {
    var data = jsonDecode(res);
    if (oper != 'fetch' && (userAdmin || table != tableUser)) debugPrint('$oper $table : $data');
    return data;
  }
}

Future<Map<String,List<int>>> kwErtragMap() async {
  List records = await Persistor.perform('query', cols: [columnId, columnKw]) as List;
  return ertragMap(records.map((e) => e as Map<String, dynamic>).toList());
}
