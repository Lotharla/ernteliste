import 'package:collection/collection.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'scrollable_widget.dart';

class TableView extends StatefulWidget {
  const TableView({super.key, required this.table, required this.updater});
  final String table;
  final void Function({dynamic item, bool? selected}) updater;
  @override
  State<TableView> createState() => TableViewState();
}
class TableViewState extends State<TableView> with AutomaticKeepAliveClientMixin {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  int? sortColumnIndex;
  bool isAscending = false;
  String? whereClause;
  @override
  void didChangeDependencies() {
    persistenceProvider.getRows(widget.table, where: whereClause);
    super.didChangeDependencies();
  }
  // ignore: unused_field
  int _counter = 0;
  void update({String? clause}) {
    setState(() {
      whereClause = clause;
      didChangeDependencies();
      _counter++;
    });
  }
  @override
  bool get wantKeepAlive => false;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // debugPrint('counter $_counter');
    return Scaffold(
      body: Consumer<PersistenceProvider>(
        builder: (context, provider, _) {
          switch (ready()) {
            case 0:
              return const Center(
                  child: Text(
                  'Keine Daten',
                  style: TextStyle(fontSize: 18),
                ));
            case < 0:
              return const Center(child: CircularProgressIndicator());
            default:
              return ScrollableWidget(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all<Color>(Colors.grey),
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                    sortAscending: isAscending,
                    sortColumnIndex: sortColumnIndex,
                    columns: _tableColumns(), 
                    rows: _tableRows()
                  ),
                );
          }
        }
      ),
    );
  }
  int ready() {
    if (persistenceProvider.isLoading) {
      return -2;
    } else  if (persistenceProvider.rows.isEmpty) {
      return 0;
    } else  if ((persistenceProvider.rows[0] as TableName).table != widget.table) {
      return -1;
    } else {
      return 1;
    }
  }
  List<DataColumn> _tableColumns() {
    // debugPrint('columns : ${columns[widget.table]!.length}');
    return [
      for (String col in columns[widget.table]!) DataColumn(label: Text(col), onSort: onSort),
    ];
  }
  List<DataRow> _tableRows() { 
    return persistenceProvider.rows.mapIndexed((index, item) => DataRow(
      cells: _rowCells(item),
      selected: item.selected,
      onSelectChanged: (bool? selected) {
        widget.updater(item: item, selected: selected);
        setState(() {});
      },
    )).toList();
  }
  List<DataCell> _rowCells(dynamic item) {
    List<DataCell> cells;
    if (item is User) {
        cells = [
          DataCell(Text(item.name)),
          DataCell(Text(item.funktion)),
          DataCell(Switch(value: item.aktiv != 0, onChanged: (value) {})),
        ];
    } else if (item is Kultur) {
        cells = [
          DataCell(Text(item.art)),
          DataCell(Text(item.sorte)),
          DataCell(Text(item.kuerzel)),
          DataCell(Switch(value: item.aktiv != 0, onChanged: (value) {})),
        ];
    } else if (item is Einheit) {
        cells = [
          DataCell(Text(item.art)),
        ];
    } else if (item is Ertrag) {
        cells = [
          DataCell(Text(item.kalenderWoche)),
          DataCell(Text(item.kultur)),
          DataCell(Text('${item.satz}')),
          DataCell(Text('${item.menge}')),
          DataCell(Text(item.einheit)),
          DataCell(Text(item.bemerkungen)),
          DataCell(Text(item.name)),
        ];
    } else {
        cells = [];
    }
    // debugPrint('row.length : ${cells.length}');
    return cells;
  }

  void onSort(int columnIndex, bool ascending) {
    final columnName = columns[widget.table]![columnIndex];
    persistenceProvider.rows.sort((item1, item2) {
      switch (columnName) {
        case columnMenge:
          return compare<double>(ascending, item1.record[columnName], item2.record[columnName]);
        case columnAktiv:
          return compare<int>(ascending, item1.record[columnName], item2.record[columnName]);
        default:
          return compare<String>(ascending, item1.record[columnName], item2.record[columnName]);
      }
    });
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }
  int compare<T>(bool ascending, T value1, T value2) {
    switch (T) {
    case int:
      return ascending
        ? (value1 as int).compareTo(value2 as int)
        : (value2 as int).compareTo(value1 as int);
    case double:
      return ascending
        ? (value1 as double).compareTo(value2 as double)
        : (value2 as double).compareTo(value1 as double);
    default:
      return ascending
        ? (value1 as String).compareTo(value2 as String)
        : (value2 as String).compareTo(value1 as String);
    }
  }
}