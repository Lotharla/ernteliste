import 'package:collection/collection.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'table_dialogs.dart';
import 'table_view.dart';

class TablesPage extends StatefulWidget {
  static const routeName = '/tables';
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
  late TabController _tabController;
  List<TableView> views = [];
  get table => views[_tabController.index].table;
  List<GlobalKey> keys = [];
  TableViewState get tabState => keys[_tabController.index].currentState! as TableViewState;
  void updateTab({String? clause}) => tabState.update(clause: clause);
  String? get whereClause => tabState.whereClause;
  @override
  void initState() {
    super.initState();
    for (var tab in tabs) {
      var key = GlobalKey<TableViewState>();
      keys.add(key);
      views.add(TableView(key: key, table: tab.text!, updater: updateSelection,));
    }
    _tabController = TabController(vsync: this, length: tabs.length, animationDuration: Duration.zero);
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
          IconButton(
            onPressed: () { filterRows(context); }, 
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter definieren',
          ),
          IconButton(
            onPressed: () { addRow(context); }, 
            icon: const Icon(Icons.add),
            tooltip: Cause.add.title,
          ),
          IconButton(
            onPressed: _index < 0 ? null : () { updateRow(context); },
            icon: const Icon(Icons.edit),
            tooltip: Cause.update.title,
          ),
          IconButton(
            onPressed: _index < 0 ? null : () { deleteRows(context); }, 
            icon: const Icon(Icons.delete),
            tooltip: Cause.delete.title2,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.mapIndexed((index, tab) => views[index]).toList(),
      ),
    );
  }

  void filterRows(BuildContext context) async {
    var where = await showDialog<String>(
      context: context, 
      builder: (BuildContext context) => FilterDialog(table: table, filter: whereClause),
    );
    if (where != null) {
      updateTab(clause: where.isNotEmpty ? where : null);
    }
  }
  void deleteRows(BuildContext context) async {
    bool? result = await confirmation(context);
    if (result ?? false) {
      await persistenceProvider.delete(null, table: tablePath(table));
      updateSelection();
      updateTab();
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
      updateTab();
    }
  }
  void addRow(BuildContext context) async {
    Map row = {};
    var result = await showDialog(
      context: context, 
      builder: (BuildContext context) => TableRowDialog(table: table, row: row),
    );
    if (result != null && result.isNotEmpty) {
      updateSelection();
      updateTab();
    }
  }
}