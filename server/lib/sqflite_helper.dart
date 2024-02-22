import 'dart:io';

import 'package:universal_platform/universal_platform.dart';

import 'package:path/path.dart';
// ignore: unnecessary_import
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

export 'package:sqflite_common_ffi/sqflite_ffi.dart';
export 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class SqfliteHelper {
  SqfliteHelper();

  String databaseFile = inMemoryDatabasePath;

  bool isMobile() {
    return UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
  }
  bool flutterTest() => Platform.environment.containsKey('FLUTTER_TEST');

  void init([String file = '']) {
    if (UniversalPlatform.isWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return;
    } else if (!isMobile()) {
      sqfliteFfiInit();
      if (flutterTest()) {
        databaseFactory = databaseFactoryFfiNoIsolate;
      } else {
        databaseFactory = databaseFactoryFfi;
      }
    }
    if (file.isNotEmpty) databaseFile = file;
  }

  Future<String> databasePath() async {
    if (isMobile()) {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, basename(databaseFile));
    } else {
      return databaseFile;
    }
  }
}
