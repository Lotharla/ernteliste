// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';

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
        case columnMenge:
          val = val == null ? '0' : '$val';
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
    return Dialog(
      child: Form(
        key: _formKey,
        child: Scaffold(
          body: Column(
            children: [
              SingleChildScrollView(
                child: Padding(
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
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: _controllers[col],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: col,
                            ),
                            focusNode: col == _columns.first ? _focusNode : null,
                          ),
                        );
                      }
                    }).toList(),
                  ),
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
                      final navi = Navigator.of(context);
                      if (_formKey.currentState!.validate()) {
                        for (String col in _columns) {
                          switch (col) {
                            case columnMenge:
                              widget.row[col] = num.parse(_controllers[col]!.text);
                              break;
                            case columnAktiv:
                              widget.row[col] = bool.parse(_controllers[col]!.text) ? 1 : 0;
                              break;
                            default:
                              widget.row[col] = _controllers[col]!.text;
                          }
                        }
                        await persistenceProvider.insertOrUpdate(widget.row, table: tablePath(widget.table));
                      }
                      navi.pop('ok');
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
