import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:server/tables.dart';
import 'package:week_of_year/week_of_year.dart';

import 'kw_model.dart';
import '../settings/settings_view.dart';
import '../ertrag_feature/ertrag_view.dart';
import '../persistence/persistence_provider.dart';

class KwListView extends StatefulWidget {
  const KwListView({super.key});

  static const routeName = '/year';

  @override
  State<KwListView> createState() => _KwListViewState();
}

class _KwListViewState extends State<KwListView> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  late AutoScrollController _controller;
  final scrollDirection = Axis.vertical;
  @override
  void initState() {
    super.initState();
    _controller = AutoScrollController(
      viewportBoundaryGetter: () =>
        Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: scrollDirection,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await loginDialog(context);
      await _scrollToIndex(KwModel.refWeek());
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KwModel.refTime,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
        key: AppConstant.globalScaffoldKey,
        appBar: AppBar(
          title: Text('Erntelisten ${KwModel.refYear()}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Kalenderwoche wählen',
              onPressed: () async {
                final values = await kwPicker(context);
                if (values != null && values.isNotEmpty) {
                  final selectedDate = values[0]!;
                  KwModel.refTime.value = selectedDate;
                  if (!context.mounted) return;
                  navigateToErtragView(context, KwModel(selectedDate.weekOfYear, selectedDate.year));
                  await _scrollToIndex(selectedDate.weekOfYear);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Jahr bestimmen',
              onPressed: () => yearPicker(context),
            ),
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
                  var kw = await persistenceProvider.addRandomErtrag(snack: true);
                  await _scrollToIndex(int.tryParse(kw.substring(kw.indexOf('-')+1))!);
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
            List<KwModel> items = KwModel.kwItems();
            return persistenceProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    scrollDirection: scrollDirection,
                    controller: _controller,
                    // Providing a restorationId allows the ListView to restore the
                    // scroll position when a user leaves and returns to the app after it
                    // has been killed while running in the background.
                    // restorationId: 'KwListView',
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = items[index];
                      return _wrapScrollTag(
                        index: items[index].woy, 
                        child: kwListTile(context, item)
                      );
                    },
                  ),
                );
          }
        ),
      );
    });
  }

  ListTile kwListTile(BuildContext context, KwModel item) {
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
        navigateToErtragView(context, item);
      }
    );
  }
  Widget _wrapScrollTag({required int index, required Widget child}) =>
    AutoScrollTag(
      key: ValueKey(index),
      controller: _controller,
      index: index,
      highlightColor: Colors.black.withOpacity(0.1),
      child: child,
    );
  Future _scrollToIndex(int index) async {
    await _controller.scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
  }
  void navigateToErtragView(BuildContext context, KwModel item) {
    Navigator.pushNamed(
      context,
      KwErtragView.routeName,
      arguments: {columnKw: item.toString(), 
        columnId: persistenceProvider.kwMap[item.toString()]}
    );
  }
}
