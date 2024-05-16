import 'package:ernteliste/src/kw_feature/kw_model.dart';
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
      persistenceProvider.kwErtraege(kw);
    }
    super.didChangeDependencies();
  }
  // ignore: unused_field
  int _counter = 0;
  void increment() {
    setState(() {
      persistenceProvider.kwErtraege(kw);
      _counter++;
    });
  }
  @override
  Widget build(BuildContext context) {
    // debugPrint('counter $_counter');
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        persistenceProvider.kwErtragMap();
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(kwString(kw)),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Erträge aus Kalenderwoche einfügen',
              onPressed: () async {
                final values = await kwPicker(context);
                if (values != null && values.isNotEmpty) {
                  String kw2 = weekOfYear(now: values[0]!);
                  await persistenceProvider.copyErtraege(kw, kw2);
                  increment();
                }
              },
            ),
            Visibility(
              visible: persistenceProvider.userIsAdmin(),
              child: IconButton(
                icon: const Icon(Icons.agriculture_outlined),
                tooltip: 'Zufallsertrag hinzufügen',
                onPressed: () async {
                  await Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag(kws: [kw]);
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
                  : ErtragListView();
          }
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var record = {columnKw: kw};
            // if (persistenceProvider.ertragList.isNotEmpty) {
            //   int last = persistenceProvider.ertragList.length - 1;
            //   for(String col in columns[tableErtrag]!) {
            //     record[col] = persistenceProvider.ertragList[last].record[col];
            //   }
            //   record[columnName] = persistenceProvider.userName;
            // }
            navigateToErtragForm(context, record);
          },
          tooltip: 'Ertrag hinzufügen',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
Future<Object?> navigateToErtragForm(BuildContext context, Map record) async {
  return Navigator.pushNamed(context, 
    ErtragForm.routeName,
    arguments: record,
  );
}
class ErtragListView extends StatelessWidget {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);

  ErtragListView({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: persistenceProvider.ertragList.length,
      itemBuilder: (context, index) {
        final ertrag = persistenceProvider.ertragList[index];
        return Dismissible(
          key: ValueKey<Ertrag>(ertrag),
          background: Container(
            color: Colors.orange,
          ),
          confirmDismiss: (direction) async {
            return await confirmation(context, singular: true);
          },
          onDismissed: (direction) async {
            persistenceProvider.ertragList.removeAt(index);
            await persistenceProvider.delete(ertrag.record);
          },
          child: _ertragListItem(context, ertrag),
        );
      });
  }
  Card _ertragListItem(BuildContext context, Ertrag ertrag) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () async {
          await navigateToErtragForm(context, ertrag.record);
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
                '$columnSatz ${satzFormat.format(ertrag.satz)}',
                style: const TextStyle(
                    fontSize: 16, color: Colors.black),
              ),
              Text(
                mengeProAnteilEinheit(ertrag),
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
        ),
      ),
    );
  }
  String mengeProAnteilEinheit(Ertrag e) => 
    '${mengeFormat.format(e.menge)} (${MengeAnteil.proAnteil(e.menge / e.anteile)}) ${e.einheit}';
}
