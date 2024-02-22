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
  State<TableView> createState() => _TableViewState();
}
class _TableViewState extends State<TableView> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  @override
  void didChangeDependencies() {
    persistenceProvider.rows = [];
    persistenceProvider.getRows(widget.table);
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
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
                    columns: _tableColumns(), 
                    rows: _tableRows()
                  ),
                );
          }
        }
      ),
    );
  }
  TableName get rowObjectName => persistenceProvider.rows[0] as TableName;
  int ready() {
    if (persistenceProvider.isLoading) {
      return -2;
    } else  if (persistenceProvider.rows.isEmpty) {
      return 0;
    } else  if (rowObjectName.table != widget.table) {
      return -1;
    } else {
      return 1;
    }
  }
  List<DataColumn> _tableColumns() {
    debugPrint('columns : ${columns[widget.table]!.length}');
    return [
      for (String col in columns[widget.table]!) DataColumn(label: Text(col)),
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
          DataCell(Text('${item.menge}')),
          DataCell(Text(item.einheit)),
          DataCell(Text(item.bemerkungen)),
          DataCell(Text(item.name)),
        ];
    } else {
        cells = [];
    }
    debugPrint('row.length : ${cells.length}');
    return cells;
  }
}