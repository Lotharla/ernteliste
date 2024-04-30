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
  Future<void> getRows(String table, {String? where, List<int>? ids}) async {
    List records = await Persistor.perform('query', path: tablePath(table), where: where, ids: ids);
    rows = records.map((r) => objectFrom(r, table)).toList();
    _propagateChange();
  }
  List column(String name) => rows.map((r) => r.record[name]).toList();
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
  Future<void> kwErtragMap() async {
    kwMap = await Persistor.kwErtragMap();
    _propagateChange();
  }
  Future<void> persistenceCheck({String? kw, int? cnt}) async {
    setLogging();
    isLoading = true;
    await setDatabase();
    for (String name in [tableKulturen, tableEinheiten]) {
      await setupTable(name);
    }
    if (cnt != null) {
      cnt -= (await Persistor.perform('count')) as int;
      await addRandomErtrag(kws: [kw], cnt: cnt);
    }
    await kwErtragMap();
    await users();
    isLoading = false;
  }
  List<Ertrag> ertragList = [];
  Future<void> kwErtraege([String kw = '']) async {
    List records = await Persistor.perform('query', kws: kw.isEmpty ? null : [kw]) as List;
    ertragList = records.map((r) => Ertrag.from(r)).toList();
    _propagateChange();
  }
  Future<void> copyErtraege(String kw1, String kw2) async {
    List records = await Persistor.perform('query', kws: [kw2]) as List;
    for (var rec in records) {
      rec[columnKw] = kw1;
    }
    await Persistor.perform('insert', data: records);
    _propagateChange();
  }
  Future<void> upsert(Map data, {String table = tableErtrag}) async {
    List<int> ids = selectedIds(table: table);
    await Persistor.perform('upsert', data: data, path: table);
    if (data[columnId] == null) {
      if (table == tableErtrag) {
        await kwErtragMap();
      }
    } else {
      ids.remove(data[columnId]);
    }
    switch (table) {
      case tableErtrag:
        await kwErtraege(data[columnKw]);
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
  Future<void> delete(Map? data, {String table = tableErtrag}) async {
    List<int> ids = data == null ? selectedIds(table: table) : [data[columnId]];
    await Persistor.perform('delete', ids: ids, path: table);
    switch (table) {
      case tableErtrag:
        await kwErtragMap();
        await kwErtraege(data == null ? '' : data[columnKw]);
        break;
      case tableUser:
        await users();
      default:
        _propagateChange();
    }
  }
  Future<List> fetch(String what, {String? where, bool multi = false}) async {
    if (multi) {
      await Persistor.multiOpen();
    }
    switch (what) {
      case columnBemerkungen:
        return await Persistor.perform('fetch', path: what) as List;
      default:
        List results = await Persistor.perform('fetch', path: tablePath(what), where: where) as List;
        switch (what) {
          case tableKulturen:
            return results.map((m) => '${m[columnArt]}, ${m[columnSorte]}, ${m[columnKuerzel]}').toList();
          case tableEinheiten:
            return results.map((m) => '${m[columnArt]}').toList();
          default:
            return results;
        }
    }
  }
  Map<String,Future<List>> multiFetch() {
    return {
      'bemerkungen' : fetch(columnBemerkungen, multi: true),
      'einheiten' : fetch(tableEinheiten, multi: true),
      'kulturen' : fetch(tableKulturen, where: rowAktiv(), multi: true),
    };
  }
  Future<List<int>> randomRecords(int cnt, {String? kw}) async {
    var einheiten = await getStrings('einheiten.txt');
    var kulturen = await getStrings('kulturen.txt');
    List<int> ids = [];
    for (var i = 0; i < cnt; i++) {
      Map rec = (await randomErtrag(kw: kw,
        year: KwModel.refTime.value.year,
        einheiten: einheiten,
        kulturen: kulturen,
        testing: testing)).record;
      var result = await Persistor.perform('upsert', data: rec) as Map?;
      if (result != null) {
        assert(result[columnId] is List && result[columnId].length == 1);
        rec[columnId] = result[columnId][0];
        assert(await Persistor.perform('upsert', data: rec) != null);
        ids.add(rec[columnId]);
      }
    }
    return ids;
  }
  Future<dynamic> addRandomErtrag({int? cnt, List<String?>? kws, snack = false}) async {
    cnt ??= 1;
    kws ??= [null];
    List<int> ids = [];
    for (var i = 0; i < kws.length; i++) {
      ids += await randomRecords(cnt, kw: kws[i]);
    }
    if (kws.length == 1 && kws[0] != null) {
      await kwErtraege(kws[0]!);
    } else {
      await kwErtragMap();
    }
    if (snack && cnt == 1) {
      var kws = await Persistor.perform('query', ids: ids, cols: [columnKw]);
      var kw = kws[0][columnKw];
      message('Zufallsertrag erstellt in Kw $kw');
      return kw;
    }
    return ids;
  }
}