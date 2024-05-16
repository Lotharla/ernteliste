// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/misc.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

import 'package:ernteliste/src/ertrag_feature/ertrag_form.dart';
import 'package:url_launcher/url_launcher.dart';

class FilterDialog extends StatefulWidget {
  final String table;
  final String? filter;
  const FilterDialog({super.key, required this.table, this.filter});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}
class _FilterDialogState extends State<FilterDialog> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  late FocusNode _focusNode;
  @override
  void initState() {
    _controller = TextEditingController(text: widget.filter);
    _focusNode = FocusNode();
    super.initState();
  }
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();
    return Dialog(
      child: Form(
        key: _formKey,
        child: Scaffold(
          body: Column(
            children: [
              PopupListComposite(
                label: 'Filterausdruck für "${widget.table}" (SQLite Where Clause)',
                list: filterSamples,
                controller: _controller,
                separator: '$andOr\n',
                focusNode: _focusNode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte einen Filterausdruck eingeben, Beispiele siehe Liste';
                  } else if (value.contains(andOr)) {
                    return "Filterausdruck ist fehlerhaft: entweder 'and' oder 'or'";
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  Uri uri = Uri.parse('https://www.sqlitetutorial.net/sqlite-where/');
                  await launchUrl(uri, mode: LaunchMode.externalApplication); 
                },
                child: const Text('Hilfe zu SQLite Where Clause'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () async {
                      String result = '';
                      if (_formKey.currentState!.validate()) {
                        result = _controller.text.trim();
                        // await persistenceProvider.getRows(widget.table, where: result);
                      }
                      if (context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TableRowDialog extends StatefulWidget {
  const TableRowDialog({super.key, required this.table, required this.row});
  final String table;
  final Map row;
  @override
  State<TableRowDialog> createState() => _TableRowDialogState();
}
class _TableRowDialogState extends State<TableRowDialog> {
  final persistenceProvider =
      Provider.of<PersistenceProvider>(AppConstant.globalNavigatorKey.currentContext!);
  late List _columns;
  final _formKey = GlobalKey<FormState>();
  final Map<String,TextEditingController> _controllers = {};
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _columns = columns[widget.table]!;
    for(String col in _columns) {
      dynamic val = widget.row[col];
      switch (col) {
        case columnSatz:
        case columnMenge:
          val = val == null ? '0' : '$val';
          break;
        case columnAnteile:
          val = val == null ? '1' : '$val';
          break;
        case columnAktiv:
          val = val == null ? 'false' : '${val != 0}';
          break;
        default:
          val ??= '';
      }
      _controllers[col] = TextEditingController(text: val);
    }
    _focusNode = FocusNode();
  }
  @override
  void dispose() {
    _focusNode.dispose();
    for(String col in _columns) _controllers[col]!.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();
    _controllers[_columns.first]!.selection = 
      TextSelection(baseOffset: 0, extentOffset: _controllers[_columns.first]!.text.length);
    return Dialog(
      child: Form(
        key: _formKey,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _columns.map((col) {
                      switch (col) {
                      case columnAktiv:
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: SwitchListTile(
                              title: Text(col),
                              value: bool.parse(_controllers[col]!.text), 
                              onChanged: (value) {
                                setState(() {
                                  _controllers[col]!.text = value ? 'true' : 'false';
                                });
                              }),
                          ),
                        );
                      default:
                        return FormTextField(col,
                          _controllers[col]!,
                          focusNode: col == _columns.first ? _focusNode : null,
                        );
                      }
                    }).toList(),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          for (String col in _columns) {
                            switch (col) {
                              case columnMenge:
                              case columnAnteile:
                                widget.row[col] = num.parse(_controllers[col]!.text);
                                break;
                              case columnAktiv:
                                widget.row[col] = bool.parse(_controllers[col]!.text) ? 1 : 0;
                                break;
                              default:
                                widget.row[col] = _controllers[col]?.text;
                            }
                          }
                          await persistenceProvider.upsert(widget.row, table: tablePath(widget.table));
                        }
                        if (context.mounted) {
                          Navigator.pop(context, 'ok');
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
