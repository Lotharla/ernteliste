// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:ernteliste/src/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ernteliste/src/app_constant.dart';
import 'package:server/tables.dart';
import 'package:provider/provider.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
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
  FocusNode? focusNode;
  late Map<String,Future<List>> lists;

  @override
  void initState() {
    super.initState();
    // focusNode = FocusNode();
    for(String col in columns[tableErtrag]!) controllers[col] = TextEditingController();
    lists = persistenceProvider.multiFetch();
  }
  @override
  void dispose() {
    // focusNode.dispose();
    for(String col in columns[tableErtrag]!) controllers[col]!.dispose();
    super.dispose();
  }
  Map args = {};
  bool get ertragNew => args[columnId] == null;
  get kw => kwString(args[columnKw] ?? weekOfYear());
  String ertragTitle() {
    if (ertragNew) {
      return 'Neuer Ertrag in $kw';
    } else {
      return 'Ertrag in $kw bearbeiten';
    }
  }
  Future<void> finishForm(BuildContext context) async {
    await Persistor.multiClose();
    if (!context.mounted) {
      return;
    }
    if (_formKey.currentState!.validate()) {
      bool confirmed = true;
      if (ertragNew) {
        confirmed = await confirmation(context, cause: Cause.add, singular: true) == true;
      }
      if (!ertragNew || confirmed) {
        for(String col in columns[tableErtrag]!) {
          args[col] = [columnMenge, columnAnteile].contains(col)
            ? mengeFormat.parse(controllers[col]!.text) 
            : controllers[col]!.text;
        }
        await persistenceProvider.upsert(args);
      }
    }
  }
  void setFocus() {
    focusNode?.requestFocus();
  }
  @override
  Widget build(BuildContext context) {
    if (args.isEmpty && widget.title == null) {
      args = (ModalRoute.of(context)!.settings.arguments ?? args) as Map;
      for(String col in columns[tableErtrag]!) {
        var val = args[col] ?? (col == columnMenge ? 0 : (col == columnAnteile ? 1 : ''));
        controllers[col]!.text = [columnMenge, columnAnteile].contains(col) 
          ? mengeFormat.format(val) 
          : val.toString();
      }
    }
    return Consumer<PersistenceProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) {
              return;
            }
            finishForm(context);
            Navigator.pop(context);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? ertragTitle()),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  FutureListComposite(
                    name: columnKultur,
                    list: lists['kulturen']!, 
                    controller: controllers[columnKultur]!,
                    focusNode: focusNode,
                  ),
                  FormTextField(
                    columnSatz,
                    controllers[columnSatz]!,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[1-9]')),
                    ],
                  ),
                  MengeAnteil(
                    anteileController: controllers[columnAnteile]!, 
                    mengeController: controllers[columnMenge]!
                  ),
                  FormTextField(
                    columnEinheit,
                    controllers[columnEinheit]!,
                  ),
                  FutureListComposite(
                    name: columnEinheit,
                    list: lists['einheiten']!, 
                    controller: controllers[columnEinheit]!
                  ),
                  FutureListComposite(
                    name: columnBemerkungen,
                    list: lists['bemerkungen']!, 
                    controller: controllers[columnBemerkungen]!
                  ),
                  FormTextField(
                    columnName,
                    controllers[columnName]!,
                    readOnly: !persistenceProvider.userIsAdmin()
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
class FutureListComposite extends StatelessWidget {
  const FutureListComposite({
    super.key,
    required this.name,
    required this.list,
    required this.controller, 
    this.focusNode,
  });
  final String name;
  final Future<List> list;
  final TextEditingController controller;
  final FocusNode? focusNode;
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
                return Completer(name, 
                  snapshot.data!.map((e) => e.toString()).toList(), 
                  controller,
                  focusNode: focusNode,
                );
              case columnBemerkungen:
              default:
                return Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: PopupListComposite(label: name, list: snapshot.data ?? [], controller: controller),
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
class PopupListComposite extends StatelessWidget {
  final String label;
  final Iterable list;
  final TextEditingController controller;
  final String separator;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  const PopupListComposite({super.key, 
    required this.label, required this.list, required this.controller,
    this.separator = '',
    this.focusNode, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FormTextField(
            label, controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            focusNode: focusNode,
            validator: validator,
          ),
        ),
        PopupMenuButton<String>(
          // icon: const Icon(Icons.arrow_drop_down),
          onSelected: (String value) {
            controller.text = controller.text.isEmpty 
              ? value 
              : '${controller.text}\n$separator$value';
          },
          itemBuilder: (BuildContext context) {
            return list
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
  final FocusNode? focusNode;
  const Completer(this.name, this.data, this.controller, {this.focusNode, super.key});
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fieldFocusNode.requestFocus();
        });
        return FormTextField(
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
class PopupDialogComposite extends StatelessWidget {
  final String label;
  final Widget Function(BuildContext) dialog;
  final TextEditingController controller;
  final String separator;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  const PopupDialogComposite({super.key, 
    required this.label, required this.dialog, required this.controller,
    this.separator = '',
    this.focusNode, this.validator,
  });
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
          const Text(
            '{_selected.year}',
          ),
          GestureDetector(
            onTap: () {
              MengeAnteil.anteilung(context, controller, 10);
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