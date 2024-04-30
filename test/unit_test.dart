// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/docs/cookbook/testing/unit/introduction

// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server/database_helper.dart';
import 'package:server/tables.dart';
import 'package:server/utils.dart';
import 'package:week_of_year/week_of_year.dart';
import 'package:date_checker/date_checker.dart';
import 'package:intl/intl.dart';

dynamic dbFile;
Future<void> checkServer(bool shouldBeAvailable) async {
  if (!shouldBeAvailable) {
    expect(() async { await killServer(); }, throwsException);
  }
  dbFile = await Persistor.perform('server');
  expect(dbFile, shouldBeAvailable ? isNotNull: isNull);
  expect(Persistor.serverAvailable, shouldBeAvailable);
  // debugPrint(dbFile.toString());
}

void main() {
  late Process p;
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await checkServer(false);
    p = await runServer();
    await checkServer(true);
  });
  tearDown(() {
    dbService.close(doit: true);
    p.kill();
  });

  group('Verschiedenes', () {
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
    test('Persistor', () async {
      var kwMap = await Persistor.kwErtragMap();
      var dbfile = dbFile;
      await checkServer(false);
      DatabaseHelper databaseHelper = DatabaseHelper(dbfile.toString());
      var db = await databaseHelper.open();
      expect(db, isNotNull);
      var results = await db!.rawQuery('select distinct $columnKw from ertrag');
      expect(results.length, kwMap.length);
      await db.close();
      Object? result = await Persistor.perform('insert', 
        data: Ertrag(weekOfYear(), 'Riesenkürbis', 3, 1, 'Stück', '', '').record
      );
      final ids = (result! as Map)[columnId];
      for (var id in ids) {
        result = await Persistor.perform('query', ids: [id]);
        result = await Persistor.perform('update', ids: [id], data: {columnBemerkungen: "***updated***"});
        result = await Persistor.perform('query', ids: [id]);
        result = await Persistor.perform('delete', ids: [id]);
      }
    });
    test('PersistenceProvider', () async {
      Persistor.serverAvailable = false;
      PersistenceProvider persistenceProvider = PersistenceProvider();
      await persistenceProvider.persistenceCheck();
      int cnt = 10;
      String woy = weekOfYear();
      await persistenceProvider.randomRecords(cnt, kw: woy);
      await persistenceProvider.kwErtraege(woy);
      expect(persistenceProvider.ertragList.length, cnt);
      await persistenceProvider.kwErtragMap();
      expect(persistenceProvider.kwMap.length, 1);
      expect(persistenceProvider.kwMap[woy]!.length, cnt);
      var woy2 = weekOfYear(plus: 1);
      await persistenceProvider.copyErtraege(woy, woy2);
      await persistenceProvider.kwErtraege(woy2);
      expect(persistenceProvider.ertragList.length, cnt);
      await persistenceProvider.kwErtragMap();
      expect(persistenceProvider.kwMap.length, 2);
      expect(persistenceProvider.kwMap[woy2]!.length, cnt);
      await persistenceProvider.fetch(columnBemerkungen);
    });
    test('Setup', () async {
      for (var serverAvailable in [false, true]) {
        Persistor.serverAvailable = serverAvailable;
        var count = {};
        for (var name in [tableKulturen, tableEinheiten]) {
          setDatabase();
          if (!Persistor.serverAvailable) {
            expect(await Persistor.perform('count', path: tablePath(name)), isZero);
            await setupTable(name);
          }
          count[name] = await Persistor.perform('count', path: tablePath(name));
          if (!Persistor.serverAvailable) {
            expect(count[name], (await defaultRecords(name)).length);
          }
          await setupTable(name);
          expect(await Persistor.perform('count', path: tablePath(name)), count[name]);
        }
        PersistenceProvider persistenceProvider = PersistenceProvider();
        var einheiten = await persistenceProvider.fetch(tableEinheiten);
        expect(einheiten.length, count[tableEinheiten]);
        for (var einheit in einheiten) expect(einheit.contains(', '), false);
        var kulturen = await persistenceProvider.fetch(tableKulturen);
        expect(kulturen.length, count[tableKulturen]);
        for (var kultur in kulturen) expect(kultur.contains(', '), true);
        kulturen = await persistenceProvider.fetch(tableKulturen, where: rowAktiv());
      }
    });
    test('Tabellen', () async {
      Persistor.serverAvailable = false;
      PersistenceProvider persistenceProvider = PersistenceProvider();
      await persistenceProvider.persistenceCheck();
      for (var table in tables) {
        Future<void> checkFilter(int sample, String name, dynamic result) async {
          await persistenceProvider.getRows(table, where: filterSamples[sample]);
          expect(persistenceProvider.rows.length, result is List ? result.length : result);
          if (result is List) {
            List column = persistenceProvider.column(name);
            column.sort((a, b) => a.toString().compareTo(b.toString()));
            expect(column, result);
          }
        }
        switch (table) {
          case tableErtrag:
            await Persistor.perform('delete', path: tablePath(table), where: 'all');
            List<String> kws = ['2024-20','2024-30','2024-40',];
            await persistenceProvider.addRandomErtrag(kws: kws);
            await checkFilter(0, columnKw, kws);
            await checkFilter(1, columnKw, kws.sublist(0, 2));
            break;
          case tableKulturen:
            await checkFilter(2, columnKuerzel, ["Kno","KüBB","KüBu","KüDel","KüHokk","KüJabL","KüSW","KüSpagh"]);
            await checkFilter(3, columnAktiv, 62);
            break;
          default:
            await persistenceProvider.getRows(table);
            expect(persistenceProvider.rows, isNotEmpty);
            print('$table : ${persistenceProvider.rows.length}');
        }
      }
    });
  });
}
