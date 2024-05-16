// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';

import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';

class FormTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLines;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? initialValue;
  final bool readOnly;
  final String? Function(String?)? validator;
  const FormTextField(this.label, this.controller, {
    this.keyboardType, 
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
    this.onFieldSubmitted,
    this.initialValue,
    this.readOnly = false,
    this.validator,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    if (autofocus) {
      selectText();
    }
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
        textAlign: textAlign,
        style: style,
        focusNode: focusNode,
        autofocus: autofocus,
        maxLines: maxLines,
        onChanged: onChanged,
        onTap: selectText,
        onFieldSubmitted: onFieldSubmitted,
        initialValue: initialValue,
        readOnly: readOnly,
        validator: validator,
      ),
    );
  }
  void selectText() {
    if (controller != null) {
      controller!.selection = TextSelection(baseOffset: 0, extentOffset: controller!.text.length);
    }
  }
}
Future loginDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const LoginDialog();
    },
  );
}
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}
class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  late FocusNode _focusNode;
  @override
  void initState() {
    persistenceProvider.persistenceCheck();
    _focusNode = FocusNode();
    super.initState();
  }
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();
    return Consumer<PersistenceProvider>(
      builder: (context, provider, _) {
        return persistenceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
            body: Container(
              margin: const EdgeInsets.all(20),
              child: Card(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FormTextField(
                            '$columnName ?', null,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            focusNode: _focusNode,
                            onFieldSubmitted: (name) {
                              if (_formKey.currentState!.validate()) {
                                persistenceProvider.setUser(name);
                                message();
                                Navigator.of(context).pop();
                              }
                              FocusScope.of(context).requestFocus(_focusNode);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty || value == Persistor.sysName) {
                                return 'Bitte einen gültigen Benutzernamen angeben';
                              }
                              if (!Persistor.userMap.containsKey(value) || Persistor.userMap[value]!.aktiv == 0) {
                                return "Dieser Benutzername ist ungültig";
                              }
                              return null;
                            },
                          ),
                        ),
                        Image.asset('assets/images/gemuese.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        // const MyImage(assetImage: AssetImage('assets/images/gemuese.png')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
      }
    );
  }
}
enum Cause { 
  add(title: 'Eintrag hinzufügen', 
    question: 'Diesen Eintrag hinzufügen', 
    title2: 'Einträge hinzufügen',
    question2: 'Einträge hinzufügen'),
  update(title: 'Eintrag bearbeiten', 
    question: 'Diesen Eintrag bearbeiten', 
    title2: '', question2: ''),
  delete(title: 'Lösche Eintrag', 
    question: 'Diesen Eintrag löschen', 
    title2: 'Lösche Einträge',
    question2: 'Markierte Einträge löschen');
  const Cause({required this.title, required this.question, required this.title2, required this.question2});
  final String title;
  final String question;
  final String title2;
  final String question2;
}
Future<bool?> confirmation(BuildContext context, {Cause cause = Cause.delete, bool singular = false}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(
        singular ? cause.title : cause.title2
      ),
      // icon: const Icon(Icons.question_mark),
      content: Text(
        '${singular ? cause.question : cause.question2} ?'
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nein'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ja'),
        ),
      ],
    ),
  );
}
class MengeAnteil extends StatefulWidget {
  static ValueNotifier<num> anteile = ValueNotifier<num>(1);
  static String proAnteil(num value) => 'pro Anteil: ${mengeFormat.format(value)}';
  static Future<num?> anteilung(BuildContext context, TextEditingController controller, {num? menge}) async {
    return showDialog<num>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Anzahl der $columnAnteile'),
        content: FormTextField(
          columnAnteile,
          controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          ],
          onFieldSubmitted: (value) {
            num? mengeProAnteil;
            if (menge != null) {
              try {
                anteile.value = max(1, mengeFormat.parse(value));
              } catch (e) {
                anteile.value = 1;
              }
              mengeProAnteil = menge / anteile.value;
            }
            Navigator.pop(context, mengeProAnteil);
          },
        ),
      )
    );
  }
  final TextEditingController anteileController;
  final TextEditingController mengeController;
  const MengeAnteil({super.key, required this.anteileController, required this.mengeController});
  @override
  State<MengeAnteil> createState() => _MengeAnteilState();
}
class _MengeAnteilState extends State<MengeAnteil> {
  late num mengeProAnteil;
  late FocusNode focusNode;
  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
  num get menge {
    try {
      return mengeFormat.parse(widget.mengeController.text);
    } catch (e) {
      return 0;
    }
  }
  num get anteile {
    try {
      return mengeFormat.parse(widget.anteileController.text);
    } catch (e) {
      return MengeAnteil.anteile.value;
    }
  }
  @override
  void didChangeDependencies() {
    mengeProAnteil = menge / anteile;
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 100,
          child: FormTextField(
            columnMenge,
            widget.mengeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            onChanged: (value) {
              setState(() {
                mengeProAnteil = menge / anteile;
              });
            },
          ),
        ),
        Expanded(
          child: IconButtonField(
            button: IconButton(
              focusNode: focusNode,
              onPressed: () async {
                var mpA = 
                  await MengeAnteil.anteilung(context, 
                    widget.anteileController, 
                    menge: menge
                  );
                setState(() {
                  if (mpA != null) {
                    mengeProAnteil = mpA;
                  }
                });
                if (!context.mounted) {
                  return;
                }
                FocusScope.of(context).requestFocus(focusNode);
              },
              icon: const Icon(Icons.widgets),
            ),
            label: MengeAnteil.proAnteil(mengeProAnteil),
          ),
        ),
      ],
    );
  }
}
class IconButtonField extends StatelessWidget {
  final IconButton button;
  final String? label;
  const IconButtonField({super.key, required this.button, this.label, });

  @override
  Widget build(BuildContext context) {
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
          Text(button.tooltip ?? label!),
          button,
        ],
      )
    );
  }
}