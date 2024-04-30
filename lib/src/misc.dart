// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:ernteliste/src/app_constant.dart';
import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:server/tables.dart';
import 'package:ernteliste/src/persistence/persistence_provider.dart';

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '$columnName ?',
                          ),
                          focusNode: _focusNode,
                          onFieldSubmitted: (name) {
                            final focusScope = FocusScope.of(context);
                            if ((persistenceProvider.userMap.containsKey(name) && 
                              persistenceProvider.userMap[name]!.aktiv != 0))
                            {
                              persistenceProvider.setUser(name);
                              if (mess != null) {
                                message(mess!);
                                // await Future.delayed(const Duration(seconds: 2));
                              }
                              Navigator.of(context).pop();
                            } else {
                              focusScope.requestFocus(_focusNode);
                            }
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
