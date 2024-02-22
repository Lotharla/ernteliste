// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:server/tables.dart';
import 'package:provider/provider.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:server/utils.dart';

class ErtragForm extends StatefulWidget {
  const ErtragForm({super.key, this.title});

  final String? title;

  static const routeName = '/ertrag';

  @override
  State<ErtragForm> createState() => _ErtragFormState();
}

class _ErtragFormState extends State<ErtragForm> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  final _formKey = GlobalKey<FormState>();
  Map<String,TextEditingController> controllers = {};
  late FocusNode focusNode;
  late Future<List> einheiten, kulturen, bemerkungen;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    for(String col in columns[tableErtrag]!) controllers[col] = TextEditingController();
    einheiten = persistenceProvider.fetch(tableEinheiten);
    kulturen = persistenceProvider.fetch(tableKulturen);
    bemerkungen = persistenceProvider.fetch(columnBemerkungen);
  }
  @override
  void dispose() {
    focusNode.dispose();
    for(String col in columns[tableErtrag]!) controllers[col]!.dispose();
    super.dispose();
  }
  void setFocus() {
    focusNode.requestFocus();
  }
  Map args = {};
  bool get ertragNeW => args['record'][columnId] == null;
  String ertragTitle() {
    var kw = kwString(args['record'][columnKw] ?? weekOfYear());
    if (ertragNeW) {
      return 'Neuer Ertrag in $kw';
    } else {
      return 'Ertrag in $kw bearbeiten';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (args.isEmpty && widget.title == null) {
      args = (ModalRoute.of(context)!.settings.arguments ?? args) as Map;
      for(String col in columns[tableErtrag]!) {
        var val = args['record'][col] ?? (col == 'Menge' ? '0' : '');
        controllers[col]!.text = val.toString();
      }
      setFocus();
    }
    return Consumer<PersistenceProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? ertragTitle()),
            actions: [
              IconButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final navi = Navigator.of(context);
                    for(String col in columns[tableErtrag]!) args['record'][col] = controllers[col]!.text;
                    await persistenceProvider.insertOrUpdate(args['record'], kw: args['record'][columnKw]);
                    // args['updater']();
                    navi.pop(true);
                  }
                }, 
                tooltip: 'Ertrag abschließen',
                icon: const Icon(Icons.agriculture),
              ),
              // IconButton(
              //   onPressed: () async {
              //     Navigator.pop(context, true);
              //   }, 
              //   icon: const Icon(Icons.access_alarm),
              // ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                ErtragTextField(
                  columnMenge,
                  controllers[columns[tableErtrag]![2]]!,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                  focusNode: focusNode,
                ),
                ErtragTextField(
                  columnEinheit,
                  controllers[columns[tableErtrag]![3]]!,
                ),
                FutureList(
                  name: columnEinheit,
                  list: einheiten, 
                  controller: controllers[columns[tableErtrag]![3]]!
                ),
                FutureList(
                  name: columnKultur,
                  list: kulturen, 
                  controller: controllers[columns[tableErtrag]![1]]!
                ),
                FutureList(
                  name: columnBemerkungen,
                  list: bemerkungen, 
                  controller: controllers[columns[tableErtrag]![4]]!
                ),
                ErtragTextField(
                  columnName,
                  controllers[columns[tableErtrag]![5]]!,
                  readOnly: !persistenceProvider.userIsAdmin()
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
class ErtragTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final int? maxLines;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? initialValue;
  final bool readOnly;
  const ErtragTextField(this.label, this.controller, {
    this.keyboardType, 
    this.inputFormatters,
    this.focusNode,
    this.maxLines,
    this.onChanged,
    this.onFieldSubmitted,
    this.initialValue,
    this.readOnly = false,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        maxLines: maxLines,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        initialValue: initialValue,
        readOnly: readOnly,
      ),
    );
  }
}
class FutureList extends StatelessWidget {
  const FutureList({
    super.key,
    required this.name,
    required this.list,
    required this.controller,
  });
  final String name;
  final Future<List> list;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: list, 
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData) {
            switch (name) {
              case columnEinheit:
                return SelectableButtons(snapshot.data!, controller);
              case columnKultur:
                return Completer(name, snapshot.data!.map((e) => e.toString()).toList(), controller);
              case columnBemerkungen:
              default:
                return Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: DropList(name: name, list: snapshot.data, controller: controller),
                );
            }
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}
class DropList extends StatelessWidget {
  final String name;
  final Iterable? list;
  final TextEditingController controller;
  const DropList({super.key, required this.name, this.list, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ErtragTextField(
            name, controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (String value) {
            controller.text = controller.text.isEmpty ? value : '${controller.text}\n$value';
          },
          itemBuilder: (BuildContext context) {
            return list!
              .map((e) => e.toString())
              .map<PopupMenuItem<String>>((String value) {
                return PopupMenuItem(value: value, child: Text(value));
              })
              .toList();
          },
        ),
      ],
    );
  }
}
class Completer extends StatefulWidget {
  final String name;
  final List<String> data;
  final TextEditingController controller;
  const Completer(this.name, this.data, this.controller, {super.key});
  @override
  State<Completer> createState() => _CompleterState();
}
class _CompleterState extends State<Completer> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        switch (textEditingValue.text) {
          case '':
            return const Iterable<String>.empty();
          case '?':
            return widget.data;
        }
        return widget.data.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      initialValue: widget.controller.value,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted) 
      {
        return ErtragTextField(
          widget.name,
          fieldTextEditingController,
          focusNode: fieldFocusNode,
          onChanged: updateController,
          onFieldSubmitted: updateController,
        );
      },
      onSelected: updateController,
    );
  }
  void updateController(String text) {
    setState(() {
      widget.controller.text = text;
    });
  }
}
class SelectableButtons extends StatefulWidget {
  final List data;
  final TextEditingController controller;
  const SelectableButtons(this.data, this.controller, {super.key});
  @override
  State<SelectableButtons> createState() => _SelectableButtonsState();
}
class _SelectableButtonsState extends State<SelectableButtons> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0, // gap between adjacent buttons
        runSpacing: 4.0, // gap between lines
        children: widget.data.map((e) => SelectableButton(
          selected: widget.controller.text == e,
          onPressed: () {
            setState(() {
              if (widget.controller.text == e) {
                widget.controller.text = '';
              } else {
                widget.controller.text = e;
              }
            });
          }, 
          child: Text(e)),
        ).toList()
      ),
    );
  }
}
class SelectableButton extends StatefulWidget {
  const SelectableButton({
    super.key,
    required this.selected,
    this.style,
    required this.onPressed,
    required this.child,
  });
  final bool selected;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<SelectableButton> createState() => _SelectableButtonState();
}
class _SelectableButtonState extends State<SelectableButton> {
  late final MaterialStatesController statesController;
  @override
  void initState() {
    super.initState();
    statesController = MaterialStatesController(
        <MaterialState>{if (widget.selected) MaterialState.selected});
  }
  @override
  void didUpdateWidget(SelectableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      statesController.update(MaterialState.selected, widget.selected);
    }
  }
  @override
  Widget build(BuildContext context) {
    return TextButton(
      statesController: statesController,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return null; // defer to the defaults
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.indigo;
            }
            return null; // defer to the defaults
          },
        ),
      ),
      onPressed: widget.onPressed,
      child: widget.child,
    );
  }
}
