import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'kw_model.dart';
import '../settings/settings_view.dart';
import '../ertrag_feature/kw_ertrag_view.dart';
import '../persistence/persistence_provider.dart';

class KwListView extends StatefulWidget {
  final List<KwModel> items;

  const KwListView(this.items, {super.key});

  static const routeName = '/year';

  @override
  State<KwListView> createState() => _KwListViewState();
}

class _KwListViewState extends State<KwListView> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  late FocusNode focusNode;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await loginDialog(context);
      setState(() {
        focusNode = FocusNode();
      });
    });
  }
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppConstant.globalScaffoldKey,
      appBar: AppBar(
        title: Text('Erntelisten ${KwModel.year()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.pushNamed(context, SettingsView.routeName);
            },
          ),
          Visibility(
            visible: persistenceProvider.userIsAdmin(),
            child: IconButton(
              icon: const Icon(Icons.agriculture_outlined),
              tooltip: 'Zufallsertrag hinzufügen',
              onPressed: () async {
                await Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag();
              },
            ),
          ),
        ],
      ),

      // To work with lists that may contain a large number of items, it’s best
      // to use the ListView.builder constructor.
      //
      // In contrast to the default ListView constructor, which requires
      // building all Widgets up front, the ListView.builder constructor lazily
      // builds Widgets as they’re scrolled into view.
      body: Consumer<PersistenceProvider>(
        builder: (context, provider, _) {
          return persistenceProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  // Providing a restorationId allows the ListView to restore the
                  // scroll position when a user leaves and returns to the app after it
                  // has been killed while running in the background.
                  restorationId: 'KwListView',
                  itemCount: widget.items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = widget.items[index];
                    return ListTile(
                      title: Text(item.description()),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          foregroundImage: persistenceProvider.kwMap.containsKey(item.toString()) 
                            ? const AssetImage('assets/images/gemuese.png')
                            : null,
                        ),
                      ),
                      onTap: () {
                        // Navigate to the details page. If the user leaves and returns to
                        // the app after it has been killed while running in the
                        // background, the navigation stack is restored.
                        Navigator.pushNamed(
                          context,
                          KwErtragView.routeName,
                          arguments: {columnKw: item.toString(), 
                            columnId: persistenceProvider.kwMap[item.toString()]}
                        );
                      }
                    );
                  },
                ),
              );
        }
      ),
      // floatingActionButton: Visibility(
      //   visible: persistenceProvider.userIsAdmin(),
      //   child: FloatingActionButton(
      //     onPressed: () {
      //       Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag();
      //     },
      //     tooltip: 'Zufallsertrag hinzufügen',
      //     child: const Icon(Icons.agriculture_outlined),
      //   ),
      // )
    );
  }
}
