import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/kw_feature/kw_model.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/navigation_service.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:ernteliste/src/tables/tables_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  String table = tableUser;
  late FocusNode focusNode;
  @override
  void initState() {
    focusNode = FocusNode();
    if (Persistor.userName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        loginDialog(context);
      });
    }
    super.initState();
  }
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
  // ignore: unused_field
  int _counter = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
          // actions: [
          // IconButton(
          //   icon: const Icon(Icons.login),
          //   tooltip: 'Erneut anmelden',
          //   onPressed: () async {
          //     loginDialog(context);
          //     setState(() {
          //       _counter++;
          //     });
          //   },
          // ),
          // Visibility(
          //   visible: persistenceProvider.userIsAdmin(),
          //   child: IconButton(
          //     icon: const Icon(Icons.table_chart),
          //     tooltip: 'Tabellen bearbeiten',
          //     onPressed: () {
          //       NavigationService().navigateToScreen(const TablesPage());
          //     },
          //   ),
          // ),
          // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<ThemeMode>(
                  // Read the selected themeMode from the controller
                  value: widget.controller.themeMode,
                  // Call the updateThemeMode method any time the user selects a theme.
                  onChanged: widget.controller.updateThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    )
                  ],
                ),
              ),
              iconField(context, 
                IconButton(
                  icon: const Icon(Icons.login),
                  tooltip: 'Erneut anmelden',
                  onPressed: () async {
                    loginDialog(context);
                    setState(() {
                      _counter++;
                    });
                  },
                )
              ),
              Visibility(
                visible: persistenceProvider.userIsAdmin(),
                child: iconField(context, 
                  IconButton(
                    icon: const Icon(Icons.table_chart),
                    tooltip: 'Tabellen bearbeiten',
                    onPressed: () {
                      NavigationService().navigateToScreen(const TablesPage());
                    },
                  )
                ),
              ),
              // YearPickerWidget(
              //   updateYear: widget.controller.updateYear,
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: ElevatedButton(
              //     onPressed: () {
              //       loginDialog(context);
              //     },
              //     child: const Text("Erneut anmelden"),
              //   ),
              // ),
              // Visibility(
              //   visible: persistenceProvider.userIsAdmin(),
              //   child: Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: ElevatedButton(
              //       onPressed: () {
              //         NavigationService().navigateToScreen(
              //           const TablesPage(), 
              //         );
              //       },
              //       child: const Text("Tabellen bearbeiten"),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Container iconField(BuildContext context, IconButton button) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(button.tooltip ?? ''),
          button,
        ],
      )
    );
  }
}

class YearPickerWidget extends StatefulWidget {
  const YearPickerWidget({super.key, required this.updateYear});
  final Future<void> Function(DateTime) updateYear;
  @override
  State<YearPickerWidget> createState() => _YearPickerWidgetState();
}
class _YearPickerWidgetState extends State<YearPickerWidget> {
  final now = DateTime.now();
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  DateTime _selected = KwModel.refTime.value;
  _selectYear(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bestimme Jahr"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(now.year - 10, 1),
              lastDate: now,
              selectedDate: _selected,
              onChanged: (DateTime dateTime) async {
                debugPrint(dateTime.year.toString());
                setState(() {
                  _selected = dateTime;
                });
                Navigator.pop(context);
                await widget.updateYear(_selected);
                await persistenceProvider.kwErtragMap();
              },
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selected.year}',
          ),
          GestureDetector(
            onTap: () {
              _selectYear(context);
            },
            child: const Icon(
              Icons.calendar_month,
            ),
          )
        ],
      ),
    );
  }
}