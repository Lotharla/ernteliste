import 'package:collection/collection.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:server/tables.dart';
import 'package:server/utils.dart';
import 'ertrag_form.dart';

class KwErtragView extends StatefulWidget {
  static const routeName = '/kw';

  final String title;

  const KwErtragView({super.key, required this.title});

  @override
  State<KwErtragView> createState() => _KwErtragViewState();
}

class _KwErtragViewState extends State<KwErtragView> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  Map args = {};
  get kw => args[columnKw] ?? weekOfYear();
  @override
  void didChangeDependencies() {
    if (args.isEmpty) {
      args = (ModalRoute.of(context)!.settings.arguments ?? args) as Map;
    }
    persistenceProvider.kwErtraege(kw);
    super.didChangeDependencies();
  }

  Future<Object?> navigateToErtragForm(BuildContext context, Map record) async {
    return Navigator.pushNamed(context, 
      ErtragForm.routeName,
      arguments: {
        'record': record,
        'updater': updateSelection,
      },
    );
  }
  // ignore: unused_field
  int _index = -1;
  void updateSelection() {
    setState(() {
      _index = persistenceProvider.firstSelectedIndex();
      // debugPrint('_index $_index');
    });
  }
  void selectErtrag(Ertrag ertrag, bool? selected) {
    ertrag.selected = selected!;
    updateSelection();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kwString(kw)),
        actions: [
          // IconButton(
          //   onPressed: _index < 0 ? null : () async {
          //     final result = await navigateToErtragForm(context, persistenceProvider.ertragList[_index].record);
          //     if (result is bool && result) {
          //       persistenceProvider.ertragList[_index].selected = false;
          //       updateSelection();
          //     }
          //   }, 
          //   icon: const Icon(Icons.edit),
          // ),
          // IconButton(
          //   onPressed: _index < 0 ? null : () async {
          //     String? result = await deletionDialog(context);
          //     if (result != null) {
          //       await persistenceProvider.delete(null, kw: kw);
          //       updateSelection();
          //     }
          //   }, 
          //   icon: const Icon(Icons.delete),
          // ),
          Visibility(
            visible: persistenceProvider.userIsAdmin(),
            child: IconButton(
              icon: const Icon(Icons.agriculture_outlined),
              tooltip: 'Zufallsertrag hinzufügen',
              onPressed: () async {
                await Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag(kw: kw);
              },
            ),
          ),
        ],
      ),
      body: Consumer<PersistenceProvider>(
        builder: (context, provider, _) {
          return persistenceProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : persistenceProvider.ertragList.isEmpty
                ? const Center(
                    child: Text(
                    'Keine Erträge',
                    style: TextStyle(fontSize: 18),
                  ))
                : _ertragListView();
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var record = {columnKw: kw};
          if (persistenceProvider.ertragList.isNotEmpty) {
            int last = persistenceProvider.ertragList.length - 1;
            for(String col in columns[tableErtrag]!) {
              record[col] = persistenceProvider.ertragList[last].record[col];
            }
            record[columnName] = persistenceProvider.userName;
          }
          navigateToErtragForm(context, record);
        },
        tooltip: 'Ertrag hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }
  // ignore: unused_element
  ListView _ertragListView() {
    return ListView.builder(
      itemCount: persistenceProvider.ertragList.length,
      itemBuilder: (context, index) {
        final ertrag = persistenceProvider.ertragList[index];
        return Card(
          elevation: 3,
          child: InkWell(
            onTap: () async {
              await navigateToErtragForm(context, ertrag.record);
            },
            child: Dismissible(
              key: ObjectKey(ertrag),
              onDismissed: (direction) async {
                var messenger = ScaffoldMessenger.of(context);
                String? result = await deletionDialog(context, thisOne: true);
                if (result != null) {
                  await persistenceProvider.delete(ertrag.record, kw: kw);
                } else {
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Eintrag blieb erhalten.\nSeite erneut aufrufen...')
                  ));
                }
              },
              child: ListTile(
                // controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.all(8.0),
                dense: false,
                title: Text(
                  ertrag.kultur,
                  style: const TextStyle(
                      fontSize: 18, color: Colors.black),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ertrag.menge} ${ertrag.einheit}',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      ertrag.bemerkungen,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black),
                    ),
                    Text(
                      ertrag.name,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                // value: ertrag.selected,
                // onChanged: (value) {
                //   selectErtrag(ertrag, value);
                // },
              ),
            ),
          ),
        );
      });
  }
  // ignore: unused_element
  DataTable _ertragTableView() {
    return DataTable(
      columns: _ertragColumns(), 
      rows: _ertragRows()
    );
  }
  List<DataColumn> _ertragColumns() {
    return [
      const DataColumn(label: Text(columnKultur)),
      const DataColumn(label: Text(columnMenge)),
      const DataColumn(label: Text(columnEinheit)),
      const DataColumn(label: Text(columnBemerkungen)),
      const DataColumn(label: Text(columnName)),
    ];
  }
  List<DataRow> _ertragRows() => persistenceProvider.ertragList
    .mapIndexed((index, ertrag) => DataRow(
      cells: _ertragCells(ertrag),
      selected: ertrag.selected,
      onSelectChanged: (bool? selected) {
        selectErtrag(ertrag, selected);
      },
    )).toList();

  List<DataCell> _ertragCells(Ertrag ertrag) {
    return [
      DataCell(Text(ertrag.kultur)),
      DataCell(Text('${ertrag.menge}')),
      DataCell(Text(ertrag.einheit)),
      DataCell(Text(ertrag.bemerkungen)),
      DataCell(Text(ertrag.name)),
    ];
  }
}
