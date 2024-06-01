import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:ernteliste/src/settings/settings_controller.dart';
import 'package:ernteliste/src/settings/settings_service.dart';
import 'package:ernteliste/src/settings/settings_view.dart';
import 'package:ernteliste/src/tables/tables_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ernteliste/src/navigation_service.dart';
import 'package:ernteliste/src/kw_feature/kw_view.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/ertrag_feature/ertrag_view.dart';
import 'package:ernteliste/src/ertrag_feature/ertrag_form.dart';
import 'package:server/tables.dart';
import 'package:server/utils.dart';

final persistenceProvider = PersistenceProvider();
final settingsController = SettingsController(SettingsService());

Future<NavigatingApp> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await persistenceProvider.persistenceCheck();
  await settingsController.loadSettings();
  var myApp = NavigatingApp(settingsController: settingsController);
  runApp(myApp);
  return myApp;
}

class NavigatingApp extends StatelessWidget {
  const NavigatingApp({
    super.key,
    required this.settingsController,
  });
  final SettingsController settingsController;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => persistenceProvider,
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (BuildContext context, Widget? child) {
          var routes = {
              KwListView.routeName: (context) => const KwListView(),
              KwErtragView.routeName: (context) => const KwErtragView(title: 'Kw'),
              ErtragForm.routeName: (context) =>  const ErtragForm(),
              TablesPage.routeName:(context) => const TablesPage(),
              SettingsView.routeName: (context) =>  SettingsView(controller: settingsController),
            };
          const route = String.fromEnvironment('ROUTE');
          return MaterialApp(
            navigatorKey: NavigationService().navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Navigating',
            // theme: ThemeData(
            //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            //   useMaterial3: true,
            // ),
            routes: routes,
            home: routes.containsKey(route) ? routes[route]!(context) : const NavigatingPage(),
          );
        },
      ),
    );
  }
}
class NavigatingPage extends StatefulWidget {
  const NavigatingPage({super.key});

  @override
  State<NavigatingPage> createState() => _NavigatingPageState();
}

class _NavigatingPageState extends State<NavigatingPage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  final kw = weekOfYear();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigating'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, SettingsView.routeName);
              },
              child: const Text("SettingsView"),
            ),
            ElevatedButton(
              onPressed: () {
                Persistor.userAdmin = true;
                Navigator.pushNamed(context, TablesPage.routeName);
              },
              child: const Text("TablesPage"),
            ),
            ElevatedButton(
              onPressed: () {
                NavigationService().navigateToScreen(
                  const KwListView(), 
                );
              },
              child: const Text("KwView"),
            ),
            ElevatedButton(
              onPressed: () {
                NavigationService().navigateToScreen(
                  const KwErtragView(title: 'Kw'), 
                  arguments: {columnKw: kw, columnId: persistenceProvider.kwMap[kw]}
                );
              },
              child: const Text("ErtragView"),
            ),
            ElevatedButton(
              onPressed: () {
                // navigateToErtragForm(context);
                int len = persistenceProvider.ertragList.length;
                NavigationService().navigateAndDisplayResult(
                  context,
                  const ErtragForm(),
                  arguments: len < 1 
                    ? {columnKw: kw}
                    : persistenceProvider.ertragList[len-1].record
                );
              },
              child: const Text("ErtragForm"),
            ),
            const SizedBox(height: 10),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag(kws: [kw]);
          _incrementCounter();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
  Future<void> navigateToErtragForm(BuildContext context) async {
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    int len = persistenceProvider.ertragList.length;
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ErtragForm(),
        settings: RouteSettings(
          arguments: len < 1 
            ? {columnKw: kw}
            : persistenceProvider.ertragList[len-1].record
        ),
      ),
    );

    // When a BuildContext is used from a StatefulWidget, the mounted property
    // must be checked after an asynchronous gap.
    if (!mounted) return;

    // After the Selection Screen returns a result, hide any previous snackbars
    // and show the new result.
    scaffoldMessenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$result')));
  }
}