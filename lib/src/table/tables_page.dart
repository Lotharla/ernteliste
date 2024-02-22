import 'package:collection/collection.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'table_row_dialog.dart';
import 'table_view.dart';

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});
  @override
  State<TablesPage> createState() => _TablesPageState();
}
class _TablesPageState extends State<TablesPage> with SingleTickerProviderStateMixin {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  static const List<Tab> tabs = [
    Tab(text: tableErtrag),
    Tab(text: tableKulturen),
    Tab(text: tableEinheiten),
    Tab(text: tableUser),
  ];
  List<TableView> views = [];
  late TabController _tabController;
  get table => views[_tabController.index].table;
  @override
  void initState() {
    super.initState();
    for (var tab in tabs) {
      views.add(TableView(table: tab.text!, updater: updateSelection,));
    }
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      updateSelection();
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    persistenceProvider.rows = [];
    super.dispose();
  }
  int _index = -1;
  void updateSelection({dynamic item, bool? selected}) {
    if (item != null) {
      item.selected = selected!;
    }
    setState(() {
      // debugPrint(persistenceProvider.list(table).map((e) => e.selected).toString());
      _index = persistenceProvider.firstSelectedIndex(table: table);
      debugPrint('_index $_index');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabellen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
        actions: [
          Visibility(
            visible: persistenceProvider.userIsAdmin(),
            child: IconButton(
              onPressed: () { addRow(context); }, 
              icon: const Icon(Icons.add),
              tooltip: 'Eintrag hinzufügen',
            ),
          ),
          Visibility(
            visible: persistenceProvider.userIsAdmin(),
            child: IconButton(
              onPressed: _index < 0 ? null : () { updateRow(context); },
              icon: const Icon(Icons.edit),
              tooltip: 'Eintrag bearbeiten',
            ),
          ),
          Visibility(
            visible: persistenceProvider.userIsAdmin(),
            child: IconButton(
              onPressed: _index < 0 ? null : () { deleteRows(context); }, 
              icon: const Icon(Icons.delete),
              tooltip: 'Eintrag löschen',
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.mapIndexed((index, tab) => views[index]).toList(),
      ),
    );
  }
  void deleteRows(BuildContext context) async {
    String? result = await deletionDialog(context);
    if (result != null) {
      await persistenceProvider.delete(null, table: tablePath(table));
      updateSelection();
    }
  }
  void updateRow(BuildContext context) async {
    final row = persistenceProvider.rows[_index];
    var result = await showDialog(
      context: context, 
      builder: (BuildContext context) {
        return TableRowDialog(table: table, row: row.record);
      },
    );
    if (result != null && result.isNotEmpty) {
      updateSelection(item: row, selected: false);
    }
  }
  void addRow(BuildContext context) async {
    var result = await showDialog(
      context: context, 
      builder: (BuildContext context) => TableRowDialog(table: table, row: const {}),
    );
    if (result != null && result.isNotEmpty) {
      updateSelection();
    }
  }
}