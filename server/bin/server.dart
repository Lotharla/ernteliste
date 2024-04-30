import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:server/database_service.dart';
import 'package:server/tables.dart';
import 'package:server/utils.dart';

late DatabaseService dbService;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/sqlite_master', _artHandler)
  ..get('/$columnBemerkungen', _artHandler)
  ..head('/einheiten', _artHandler)
  ..get('/einheiten', _artHandler)
  ..post('/einheiten', _artHandler)
  ..head('/kulturen', _artHandler)
  ..get('/kulturen', _artHandler)
  ..post('/kulturen', _artHandler)
  ..get('/user', _ertragHandler)
  ..post('/user', _ertragHandler)
  ..get('/ertrag', _ertragHandler)
  ..post('/ertrag', _ertragHandler)
  ..put('/ertrag', _ertragHandler)
  ..patch('/ertrag', _ertragHandler)
  ..delete('/ertrag', _ertragHandler)
  ..get('/table/<table>', _tableHandler)
  ..post('/table/<table>', _tableHandler)
  ..get('/count/<table>', _tableHandler)
  ..post('/setup/<table>', _tableHandler)
  ..put('/table/<table>', _tableHandler)
  ..patch('/table/<table>', _tableHandler)
  ..delete('/table/<table>', _tableHandler)
  ..get('/bye/<message>', (Request request) {
      exit(0);
    //   var message = request.params['message'];
    //   return Response.ok('$message\n');
    });

Future<Response> _rootHandler(Request req) async {
  await dbService.touch();
  var databaseFile = dbService.databaseFile;
  if (await File(databaseFile).exists()) {
    return Response.ok(databaseFile);
  } else {
    return Response.notFound(databaseFile);
  }
}

List<String>? queryParameterList(Uri url, key) {
  List<String>? lst;
  var params = url.queryParameters[key];
  try {
    if (params != null && params.startsWith('[')) {
      lst = (jsonDecode(params) as List).map((e) => e as String).toList();
    } else {
      lst = url.queryParametersAll[key];
    }
  } catch (e) {
    lst = null;
  }
  return lst;
}
List<int>? queryParameterId(Request req) {
  List<int>? ids;
  var idParams = req.url.queryParameters['id'];
  try {
    if (idParams != null && idParams.startsWith('[')) {
      ids = (jsonDecode(idParams) as List).map((e) => e as int).toList();
    } else {
      ids = (req.url.queryParametersAll['id'] as List).map((e) => int.parse(e)).toList();
    }
  } catch (e) {
    ids = [];
  }
  return ids;
}
bool jsonContent(Request req) => req.headers['Content-Type']!.contains('application/json');

Future<Response> _ertragHandler(Request req) async {
  dynamic res = [];
  String table = req.url.path == 'user' ? tableUser : tableErtrag;
  try {
    switch (req.method) {
      case 'GET':
        var who = queryParameterList(req.url, 'who');
        if (who != null) {
          var funk = queryParameterList(req.url, 'funk');
          res = jsonEncode(
            await dbService.isUser(
              who[0], 
              funk: funk != null && funk.isNotEmpty && funk[0] != 'null' ? funk[0] : null
          ));
        } else {
          return _tableHandler(req, table);
        }
        break;
      default:
        return _tableHandler(req, table);
    }
  } catch (e) {
    print(e);
  } 
  return Response.ok(res, headers: { 'Content-Type': 'application/json' });
}
Future<Response> _tableHandler(Request req, String table) async {
  dynamic res = [];
  List<String>? kws = queryParameterList(req.url, 'kw');
  List<int>? ids;
  if (kws == null) {
    ids = queryParameterId(req);
  }
  List<String>? cols = queryParameterList(req.url, 'column');
  List<String>? wheres = queryParameterList(req.url, 'where');
  String? where = wheres == null ? null : wheres[0];
  try {
    final String json = ['GET', 'DELETE'].contains(req.method) ? '' : await req.readAsString();
    switch (req.method) {
      case 'GET':
        if (pathStartsWith(req.url.path, 'count')) {
          res = await dbService.serve('count', table: table);
        } else {
          res = await dbService.serve('query', where: where, ids: ids, kws: kws, cols: cols, table: table);
        }
        break;
      case 'POST':
        if (jsonContent(req)) {
          var oper = pathStartsWith(req.url.path, 'setup') ? 'Setup' : 'insert';
          res = await dbService.serve(oper, json: json, table: table);
        }
        break;
      case 'PUT':
        if (jsonContent(req)) {
          res = await dbService.serve('update', where: where, ids: ids, json: json, table: table);
        }
        break;
      case 'PATCH':
        if (jsonContent(req)) {
          res = await dbService.serve('upsert', where: where, json: json, table: table);
        }
        break;
      case 'DELETE':
        res = await dbService.serve('delete', where: where, ids: ids, table: table);
        break;
    }
  } catch (e) {
    print(e);
  }
  return Response.ok(res, headers: { 'Content-Type': 'application/json' });
}
Future<Response> _artHandler(Request req) async {
  Map<String, String> headers = { 'Content-Type': 'application/json' };
  dynamic res = [];
  try {
    switch (req.method) {
      case 'HEAD':
        if (req.headers.containsKey('X_CLEAR_TABLE')) {
          res = await dbService.serve('clear', table: req.url.path);
        } else {
          var exists = await dbService.serve('exist', table: req.url.path);
          headers['X_CHECK_TABLE'] = exists.toString();
        }
        break;
      case 'GET':
        res = await dbService.serve('fetch', table: req.url.path);
        break;
      case 'POST':
        String json = await req.readAsString();
        res = await dbService.serve('setup', table: req.url.path, json: json);
        break;
    }
  } catch (e) {
    print(e);
  }
  // print(headers);
  return Response.ok(res, headers: headers);
}

void main(List<String> args) async {
  final config = await getConfig();
  final databaseFile = Platform.environment['DATABASE'] ?? config['database'];
  dbService = DatabaseService.initialize(file: databaseFile);

  final parser = ArgParser();
  parser.addFlag('help', negatable: false);
  parser.addFlag('clear', negatable: false, help: 'clear Ertrag table');
  parser.addOption('fill', help: 'insert [num] random records into Ertrag table');
  parser.addOption('setup', help: 'fill [table] with predefined values that will be suggested in Ertrag form', 
    valueHelp: 'table',
    allowedHelp: {'einheiten': 'suggestions for Einheiten', 'kulturen': 'suggestions for Kulturen'});
  final results = parser.parse(args);
  if (results.wasParsed('help')) {
    await dbService.info();
    print(parser.usage);
    exit(0);
  }
  if (results.wasParsed('clear') || results.wasParsed('fill') || results.wasParsed('setup')) {
    if (results.wasParsed('clear')) {
      await dbService.serve('clear');
    }
    if (results.wasParsed('fill')) {
      int cnt = int.parse(results['fill']);
      List ertraege = [for (int i=0; i<cnt; i++) (await randomErtrag()).record];
      await dbService.serve('insert', json: jsonEncode(ertraege));
    }
    if (results.wasParsed('setup')) {
      final table = results['setup'];
      dynamic data = await loadStrings('$table.txt');
      await dbService.serve('setup', 
        table: table,
        json: data != null ? jsonEncode(data) : "",
      );
   }
    exit(0);
  }

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsHeaders())
    .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? "${config['port']}");
  final server = await serve(handler, ip, port);
  print(serverListening(port: '${server.port}'));
}
