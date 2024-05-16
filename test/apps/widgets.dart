import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:ernteliste/apps/navigating.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/ertrag_feature/ertrag_form.dart';
import 'package:ernteliste/src/kw_feature/kw_model.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/navigation_service.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:ernteliste/src/settings/settings_controller.dart';
import 'package:ernteliste/src/settings/settings_service.dart';
import 'package:ernteliste/src/settings/settings_view.dart';
import 'package:ernteliste/src/tables/table_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';
import 'package:week_of_year/week_of_year.dart';

final persistenceProvider = PersistenceProvider();
final settingsController = SettingsController(SettingsService());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await persistenceProvider.persistenceCheck(cnt: 5);
  await settingsController.loadSettings();
  runApp(const WidgetsApp());
}
class WidgetsApp extends StatelessWidget {
  const WidgetsApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => persistenceProvider,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, 
          navigatorKey: AppConstant.globalNavigatorKey,
          home: const WidgetsScreen(),
        ),
    );
  }
}
class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});
  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}
class _WidgetsScreenState extends State<WidgetsScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<List> bemerkungen;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loginDialog(context);
    });
    Persistor.userAdmin = true;
  }
  @override
  void didChangeDependencies() {
    bemerkungen = persistenceProvider.fetch(columnBemerkungen);
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Widgets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Jahr bestimmen',
            onPressed: () => yearPicker(context),
            // onPressed: () async {
            //   final initialDate = DateTime.now();
            //   final newDate = await showDatePicker(
            //     firstDate: DateTime(initialDate.year - 10),
            //     lastDate: DateTime(initialDate.year + 10),
            //     context: context,
            //     initialDate: initialDate,
            //     initialDatePickerMode: DatePickerMode.day,
            //   );
            //   if (newDate == null) {
            //     return;
            //   }
            //   if (!context.mounted) return;
            //   // navigateToErtragView(context, KwModel(newDate.weekOfYear, newDate.year));
            // },
          ),
          IconButton(
            onPressed: () async {
              bool? result = await confirmation(context);
              debugPrint(result.toString());
            }, 
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () async {
              var result = await showDialog(
                context: context, 
                builder: (BuildContext context) => const FilterDialog(table: tableErtrag,),
              );
              debugPrint(result);
            }, 
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () async {
              NavigationService().navigateToScreen(const NavigatingPage());
            }, 
            icon: const Icon(Icons.beach_access),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(children: [
            ElevatedButton(
              onPressed: () async {
                final result = (await Navigator.push(
                  context,
                  MaterialPageRoute<DateTime>(builder: (context) => DatePicker(initialDate: _selectedDate)),
                ))!;
                setState(() {
                  _selectedDate = result;
                });
              },
              child: Text(_selectedDate.toString().split(' ').first),
            ),
            ElevatedButton(
              onPressed: () async {
                final values = await showCalendarDatePicker2Dialog(
                  context: context,
                  config: CalendarDatePicker2WithActionButtonsConfig(
                    weekNumbers: true,
                    weekNumberLabel: 'Kw',
                    weekNumberTextStyle: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  dialogSize: const Size(400, 400),
                  borderRadius: BorderRadius.circular(15),
                  value: [_selectedDate],
                  dialogBackgroundColor: Colors.white,
                );
                if (values != null) {
                  setState(() {
                    _selectedDate = values[0]!;
                  });
                }
              },
              child: Text('Kw ${_selectedDate.weekOfYear}'),
            ),
            YearPickerWidget(updateYear: SettingsController(SettingsService()).updateYear),
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
            ElevatedButton(
              onPressed: () async {
                num? mengeProAnteil = 
                  await MengeAnteil.anteilung(context, 
                    TextEditingController(text: '${MengeAnteil.anteile}'), 
                    menge: 10);
                debugPrint('mengeProAnteil: $mengeProAnteil');
              },
              child: const Text('Anteile'),
            ),
            MengeAnteil(
              anteileController: TextEditingController(text: '${MengeAnteil.anteile}'), 
              mengeController: TextEditingController(text: '10')
            ),
            FutureListComposite(
              name: columnBemerkungen,
              list: bemerkungen, 
              controller: TextEditingController(text: 'bla'),
            ),
            FormTextField('label', TextEditingController(text: 'xxx')),
            TextFormField(controller: TextEditingController(text: 'xyz')),
          ]),
        ),
      ),
    );
  }
}

class DatePicker extends StatelessWidget {
  final DateTime initialDate;

  const DatePicker({required this.initialDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Date"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop<DateTime>(context, initialDate),
        ),
      ),
      body: Center(
        child: Container(
          color: Colors.blue[50],
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(10.0),
          child: CalendarDatePicker2(
            config: CalendarDatePicker2Config(),
            value: [initialDate],
            onValueChanged: (selectedDates) {
              Navigator.pop<DateTime>(context, selectedDates[0]);
            },
          ),
          // child: CalendarDatePicker(
          //   initialDate: initialDate,
          //   firstDate: DateTime(2021),
          //   lastDate: DateTime(2025),
          //   onDateChanged: (DateTime selectedDate) {
          //     Navigator.pop<DateTime>(context, selectedDate);
          //   },
          // ),
        ),
      ),
    );
  }
}