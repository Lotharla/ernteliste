import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
	
void main() => runApp(const MyApp());
	
class AppNotifier with ChangeNotifier{
  String text = "Kolak";

  setText(){
    text = "Berubah";
    notifyListeners();
  }

  getText(){
    return text;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suhu Converter',
      home: ChangeNotifierProvider(
        create: (ctx) => AppNotifier(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("App Ku"),
          ),
          body: Consumer<AppNotifier>(
            builder: (ctx, data, _){
              return Text(data.getText());
            },
          ),
          floatingActionButton: Consumer<AppNotifier>(
            builder: (ctx, data, _){
              return FloatingActionButton(
                child: const Text("Ubah"),
                onPressed: (){
                  data.setText();
                },
              );
            },
          )
        ),
      )
    );
  }
}

