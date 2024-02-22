import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/settings/settings_controller.dart';
import 'package:ernteliste/src/settings/settings_service.dart';
import 'package:ernteliste/src/settings/settings_view.dart';
import 'package:ernteliste/src/table/table_row_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => PersistenceProvider(),
      child: MaterialApp(
          debugShowCheckedModeBanner: false, 
          navigatorKey: AppConstant.globalNavigatorKey,
          home: const DialogScreen(),
        ),
    );
  }
}
class DialogScreen extends StatefulWidget {
  const DialogScreen({super.key});
  @override
  State<DialogScreen> createState() => _DialogScreenState();
}
class _DialogScreenState extends State<DialogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loginDialog(context);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Dialoge"),
        actions: [
          IconButton(
            onPressed: () async {
              String? result = await deletionDialog(context);
              debugPrint(result.toString());
            }, 
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          YearPickerWidget(controller: SettingsController(SettingsService())),
          ElevatedButton(
            onPressed: () async {
              Map data = {'Wer': 'dev', 'Funktion': 'admin', 'aktiv': 1};
              var result = await showDialog(
                context: context, 
                builder: (BuildContext context) => TableRowDialog(table: tableUser, row: data),
              );
              debugPrint(result);
              debugPrint(data.toString());
            },
            child: const Text('TableRowDialog'),
          ),
        ]),
      ),
    );
  }
}
