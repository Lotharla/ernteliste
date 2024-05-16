import 'package:intl/intl.dart';

final mengeFormat = NumberFormat("##0.##", 'de_DE');
final satzFormat = NumberFormat("#0", 'de_DE');

const columnId = 'rowid';
const tableUser = 'User';
const columnName = 'Wer';
const columnFunktion = 'Funktion';
const columnAktiv = 'aktiv';
const tableErtrag = 'Ertrag';
const columnKw = 'Kalenderwoche';
const columnMenge = 'Menge';
const columnAnteile = 'Anteile';
const columnEinheit = 'Einheit';
const columnKultur = 'Kultur';
const columnSatz = 'Satz';
const columnBemerkungen = 'Bemerkungen';
const tableKulturen = 'Kulturen';
const tableEinheiten = 'Einheiten';
const columnArt = 'Art';
const columnSorte = 'Sorte';
const columnKuerzel = 'Kürzel';
const columnFarbe = 'Farbe';
const columnEinst = 'Einstellungen';

final tables = [tableErtrag,tableKulturen,tableEinheiten,tableUser];
final columns = {
  tableUser: [columnName,columnFunktion,columnAktiv,columnEinst],
  tableErtrag: [columnKw,columnKultur,columnSatz,columnMenge,columnAnteile,columnEinheit,
    columnBemerkungen,columnName],
  tableKulturen: [columnArt,columnSorte,columnKuerzel,columnAktiv,columnFarbe],
  tableEinheiten: [columnArt],
};
String rowAktiv() => '$columnAktiv <> 0';

mixin TableName {
  late String table;
  bool selected = false;
}
class Ertrag with TableName {
  Ertrag(this.kalenderWoche, this.kultur, this.satz, this.menge, this.anteile, this.einheit, this.bemerkungen, this.name, {this.id}) {
    table = tableErtrag;
  }
  int? id;
  String kalenderWoche;
  String kultur;
  int satz;
  num menge, anteile;
  String einheit;
  String bemerkungen;
  String name;
  factory Ertrag.from(Map<String, dynamic> rec) {
    return Ertrag(
      rec[columnKw] ?? '',
      rec[columnKultur] ?? '',
      rec[columnSatz] ?? 1,
      rec[columnMenge] ?? 0.0,
      rec[columnAnteile] ?? 0.0,
      rec[columnEinheit] ?? '',
      rec[columnBemerkungen] ?? '',
      rec[columnName] ?? '',
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnKw: kalenderWoche,
      columnKultur: kultur,
      columnSatz: satz,
      columnMenge: menge,
      columnAnteile: anteile,
      columnEinheit: einheit,
      columnBemerkungen: bemerkungen,
      columnName: name
    };
  }
  @override
  String toString() {
    return record.toString();
  }
}
class User with TableName {
  User(this.name, this.funktion, this.aktiv, this.einstellungen, {this.id = 0}) {
    table = tableUser;
  }
  int id;
  String name;
  String funktion;
  int aktiv;
  String einstellungen;
  factory User.from(Map<String, dynamic> rec) {
    return User(
      rec[columnName] ?? '',
      rec[columnFunktion] ?? '',
      rec[columnAktiv] ?? 0,
      rec[columnEinst] ?? '{}',
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnName: name,
      columnFunktion: funktion,
      columnAktiv: aktiv,
      columnEinst: einstellungen,
    };
  }
  @override
  String toString() {
    return record.toString();
  }
}
var setupUser = ['''
  INSERT OR IGNORE INTO $tableUser ($columnName, $columnFunktion, $columnAktiv, $columnEinst) 
  VALUES ('sys', '', 0, '{"$columnAnteile" : 1}')
  ''', '''
  INSERT OR IGNORE INTO $tableUser ($columnName, $columnFunktion, $columnAktiv, $columnEinst) 
  VALUES ('dev', 'admin', 1, '{}')
  ''', '''
  INSERT OR IGNORE INTO $tableUser ($columnName, $columnFunktion, $columnAktiv, $columnEinst) 
  VALUES ('usr', 'user', 1, '{}')
  '''];
class Kultur with TableName {
  Kultur(this.art, this.sorte, this.kuerzel, this.aktiv, this.farbe, {this.id = 0}) {
    table = tableKulturen;
  }
  int id;
  String art;
  String sorte;
  String kuerzel;
  int aktiv;
  String farbe;
  factory Kultur.from(Map<String, dynamic> rec) {
    return Kultur(
      rec[columnArt] ?? '',
      rec[columnSorte] ?? '',
      rec[columnKuerzel] ?? '',
      rec[columnAktiv] ?? 0,
      rec[columnFarbe] ?? '',
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnArt: art,
      columnSorte: sorte,
      columnKuerzel: kuerzel,
      columnAktiv: aktiv,
      columnFarbe: farbe,
    };
  }
  @override
  String toString() {
    return record.toString();
  }
}
class Einheit with TableName {
  Einheit(this.art, {this.id = 0}) {
    table = tableEinheiten;
  }
  int id;
  String art;
  factory Einheit.from(Map<String, dynamic> rec) {
    return Einheit(
      rec[columnArt] ?? '',
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnArt: art,
    };
  }
  @override
  String toString() {
    return record.toString();
  }
}

Object? objectFrom(Map<String, dynamic> rec, String table) {
  switch (table) {
    case tableErtrag:
      return Ertrag.from(rec);
    case tableUser:
      return User.from(rec);
    case tableKulturen:
      return Kultur.from(rec);
    case tableEinheiten:
      return Einheit.from(rec);
    default:
      return null;
  }
}
const andOr = 'and | or';
const filterSamples = [
  "$columnKw = '2024-30' or $columnKw <> '2024-30'",
  "$columnKw >= '2024-20' and $columnKw < '2024-40'",
  "$columnKuerzel LIKE 'Kü%' or $columnKuerzel LIKE 'Kn_'",
  "$columnAktiv = 0 and $columnAktiv != 1",
];
