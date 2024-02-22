import 'package:ernteliste/src/kw_feature/kw_model.dart';
import 'package:flutter/foundation.dart';
import 'package:server/tables.dart';
import 'package:server/utils.dart';
import 'persistor.dart';

class PersistenceProvider extends ChangeNotifier {
  bool testing = !kIsWeb && flutterTest();
  bool isLoading = false;
  void _propagateChange() {
    notifyListeners();
  }
  List rows = [];
  Future<void> getRows(String table) async {
    List records = await Persistor.perform('query', path: tablePath(table));
    rows = records.map((r) => objectFrom(r, table)).toList();
    _propagateChange();
  }
  List list(String table) {
    if (rows.isNotEmpty) {
      return rows;
    } else {
      switch (table) {
        case tableUser:
          return userMap.values.toList();
        case tableErtrag:
          return ertragList;
        default:
          return [];
    }
    }
  }
  List<int> selectedIds({String table = tableErtrag}) {
    List<int> ids = [];
    List lst = list(table);
    for (var i = 0; i < lst.length; i++) {
      if (lst[i].selected) {
        ids.add(lst[i].id);
      }
    }
    return ids;
  }
  int firstSelectedIndex({String table = tableErtrag}) {
    List lst = list(table);
    for (var i = 0; i < lst.length; i++) {
      if (lst[i].selected) {
        return i;
      }
    }
    return -1;
  }
  Map<String,User> userMap = {};
  Future<void> users() async {
    List records = await Persistor.perform('query', path: tableUser);
    userMap = {};
    for (var r in records) {
      userMap[r[columnName]] = User.from(r);
    }
    _propagateChange();
  }
  String userName = '';
  void setUser(name) {
    userName = name;
    Persistor.userAdmin = userIsAdmin();
    _propagateChange();
  }
  bool userIsAdmin({String? name}) {
    name = name ?? userName;
    if (userMap.containsKey(name)) {
      return userMap[name]!.funktion == 'admin';
    } else {
      return false;
    }
  }
  Map<String,List<int>> kwMap = {};
  Future<void> persistenceCheck({String? kw, int? cnt}) async {
    isLoading = true;
    await setDatabase();
    await setupTables();
    if (cnt != null) {
      await addRandomErtrag(kw: kw, cnt: cnt);
    }
    kwMap = await kwErtragMap();
    isLoading = false;
    await users();
  }
  List<Ertrag> ertragList = [];
  Future<void> kwErtraege([String kw = '']) async {
    List records = await Persistor.perform('query', kws: kw.isEmpty ? null : [kw]) as List;
    ertragList = records.map((r) => Ertrag.from(r)).toList();
    _propagateChange();
  }
  Future<void> insertOrUpdate(Map data, {String table = tableErtrag, String kw = ''}) async {
    List<int> ids = selectedIds(table: table);
    await Persistor.perform('replace', data: data, path: table);
    if (data[columnId] == null) {
      if (table == tableErtrag) {
        kwMap = await kwErtragMap();
      }
    } else {
      ids.remove(data[columnId]);
    }
    switch (table) {
      case tableErtrag:
        await kwErtraege(kw);
        break;
      case tableUser:
        await users();
      default:
        _propagateChange();
    }
    for (var item in list(table)) {
      if (ids.contains(item.id)) {
        item.selected = true;
      }
    }
  }
  Future<void> delete(Map? data, {String table = tableErtrag, String kw = ''}) async {
    List<int> ids = data == null ? selectedIds(table: table) : [data[columnId]];
    await Persistor.perform('delete', ids: ids, path: table);
    switch (table) {
      case tableErtrag:
        kwMap = await kwErtragMap();
        await kwErtraege(kw);
        break;
      case tableUser:
        await users();
      default:
        _propagateChange();
    }
  }
  Future<List> fetch(String table) async {
    return await Persistor.perform('fetch', path: table) as List;
  }
  Future<void> randomRecords(int cnt, {String? kw}) async {
    var einheiten = await getStrings('einheiten.txt');
    var kulturen = await getStrings('kulturen.txt');
    for (var i = 0; i < cnt; i++) {
      Map rec = (await randomErtrag(kw: kw,
        year: KwModel.refTime.year,
        einheiten: einheiten,
        kulturen: kulturen,
        testing: testing)).record;
      var result = await Persistor.perform('replace', data: rec) as Map?;
      if (result != null) {
        assert(result[columnId] is List && result[columnId].length == 1);
        rec[columnId] = result[columnId][0];
        assert(await Persistor.perform('replace', data: rec) != null);
      }
    }
  }
  Future<void> addRandomErtrag({String? kw, int? cnt}) async {
    await Persistor.perform('server');
    await randomRecords(cnt ?? 1, kw: kw);
    if (kw != null) {
      await kwErtraege(kw);
    } else {
      kwMap = await kwErtragMap();
      _propagateChange();
    }
  }
}