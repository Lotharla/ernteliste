import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/app_constant.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PersistenceProvider(),
      child:  MaterialApp(
        navigatorKey: AppConstant.globalNavigatorKey,
        debugShowCheckedModeBanner: false,
        home: const MyHome(),
      ),
    );
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}
class _MyHomeState extends State<MyHome> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  @override
  void initState() {
    persistenceProvider.persistenceCheck();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppConstant.globalScaffoldKey,
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: Consumer<PersistenceProvider>(
        builder: (context, persistenceProvider, _) {
          return Text(persistenceProvider.kwMap.toString());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<PersistenceProvider>(context, listen: false).addRandomErtrag();
        },
        child: const Icon(Icons.refresh),
      )
    );
  }
}