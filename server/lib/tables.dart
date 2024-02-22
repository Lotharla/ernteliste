const columnId = 'rowid';
const tableUser = 'User';
const columnName = 'Wer';
const columnFunktion = 'Funktion';
const columnAktiv = 'aktiv';
const tableErtrag = 'Ertrag';
const columnKw = 'Kalenderwoche';
const columnMenge = 'Menge';
const columnEinheit = 'Einheit';
const columnKultur = 'Kultur';
const columnBemerkungen = 'Bemerkungen';
const tableKulturen = 'Kulturen';
const tableEinheiten = 'Einheiten';
const columnArt = 'Art';
const columnSorte = 'Sorte';
const columnKuerzel = 'Kürzel';

final tables = [tableErtrag,tableKulturen,tableEinheiten,tableUser];
final columns = {
  tableUser: [columnName,columnFunktion,columnAktiv],
  tableErtrag: [columnKw,columnKultur,columnMenge,columnEinheit,columnBemerkungen,columnName],
  tableKulturen: [columnArt,columnSorte,columnKuerzel,columnAktiv],
  tableEinheiten: [columnArt],
};
mixin TableName {
  late String table;
}
class Ertrag with TableName {
  Ertrag(this.kalenderWoche, this.kultur, this.menge, this.einheit, this.bemerkungen, this.name, {this.id}) {
    table = tableErtrag;
  }
  int? id;
  String kalenderWoche;
  String kultur;
  num menge;
  String einheit;
  String bemerkungen;
  String name;
  bool selected = false;
  factory Ertrag.from(Map<String, dynamic> rec) {
    return Ertrag(
      rec[columnKw] ?? '',
      rec[columnKultur] ?? '',
      rec[columnMenge] ?? 0,
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
      columnMenge: menge,
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
  User(this.name, this.funktion, this.aktiv, {this.id = 0}) {
    table = tableUser;
  }
  int id;
  String name;
  String funktion;
  int aktiv;
  bool selected = false;
  factory User.from(Map<String, dynamic> rec) {
    return User(
      rec[columnName] ?? '',
      rec[columnFunktion] ?? '',
      rec[columnAktiv] ?? 0,
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnName: name,
      columnFunktion: funktion,
      columnAktiv: aktiv
    };
  }
  @override
  String toString() {
    return record.toString();
  }
}
class Kultur with TableName {
  Kultur(this.art, this.sorte, this.kuerzel, this.aktiv, {this.id = 0}) {
    table = tableKulturen;
  }
  int id;
  String art;
  String sorte;
  String kuerzel;
  int aktiv;
  bool selected = false;
  factory Kultur.from(Map<String, dynamic> rec) {
    return Kultur(
      rec[columnArt] ?? '',
      rec[columnSorte] ?? '',
      rec[columnKuerzel] ?? '',
      rec[columnAktiv] ?? 0,
      id: rec[columnId]
    );
  }
  Map<String, Object?> get record {
    return {
      columnId: id,
      columnArt: art,
      columnSorte: sorte,
      columnKuerzel: kuerzel,
      columnAktiv: aktiv
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
  bool selected = false;
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
