// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/docs/cookbook/testing/unit/introduction

// ignore_for_file: avoid_print

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

void main() {
  late Process p;
  setUp(() async {
    await killServer();
    p = await runServer();
  });

  tearDown(() => p.kill());

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
      expect(DateTime(2020, 12, 28).weekOfYear, 53);
    });
    test('persistor', () async {
      WidgetsFlutterBinding.ensureInitialized();
      var dbFile = await checkServer(true);
      var kwMap = await kwErtragMap();
      await Persistor.perform('bye');
      await checkServer(false);
      DatabaseHelper databaseHelper = DatabaseHelper(dbFile.toString());
      var db = await databaseHelper.open();
      expect(db, isNotNull);
      var results = await db!.rawQuery('select distinct $columnKw from ertrag');
      expect(results.length, kwMap.length);
      await db.close();
      Object? result = await Persistor.perform('insert', 
        data: Ertrag(weekOfYear(), 'Riesenkürbis', 1, 'Stück', '', '').record
      );
      final ids = (result! as Map)[columnId];
      for (var id in ids) {
        result = await Persistor.perform('query', ids: [id]);
        result = await Persistor.perform('update', ids: [id], data: {columnBemerkungen: "***updated***"});
        result = await Persistor.perform('query', ids: [id]);
        result = await Persistor.perform('delete', ids: [id]);
      }
    });
    test('persistence provider', () async {
      WidgetsFlutterBinding.ensureInitialized();
      PersistenceProvider persistenceProvider = PersistenceProvider();
      await persistenceProvider.persistenceCheck();
      expect(Persistor.serverAvailable, false);
      expect(await exist(tableEinheiten), true);
      expect(await exist(tableKulturen), true);
      int cnt = 10;
      var woy = weekOfYear();
      await persistenceProvider.randomRecords(cnt, kw: woy);
      await persistenceProvider.kwErtraege(woy);
      expect(persistenceProvider.ertragList.length, cnt);
      await persistenceProvider.persistenceCheck();
      expect(persistenceProvider.kwMap.length, 1);
      expect(persistenceProvider.kwMap[woy]!.length, cnt);
      await checkServer(true);
    });
    test('tabellen', () async {
      WidgetsFlutterBinding.ensureInitialized();
      await checkServer(true);
      PersistenceProvider persistenceProvider = PersistenceProvider();
      await persistenceProvider.persistenceCheck();
      await persistenceProvider.addRandomErtrag(cnt: 3);
      for (var table in tables) {
        persistenceProvider.rows = [];
        await persistenceProvider.getRows(table);
        expect(persistenceProvider.rows, isNotEmpty);
        switch (table) {
          case tableEinheiten:
            print(persistenceProvider.rows);
            break;
          default:
        }
      }
    });
  });
}

Future<Object?> checkServer(bool shouldBeAvailable) async {
  var dbFile = await Persistor.perform('server');
  debugPrint(dbFile.toString());
  expect(dbFile, shouldBeAvailable ? isNotNull : isNull);
  expect(Persistor.serverAvailable, shouldBeAvailable);
  return dbFile;
}
