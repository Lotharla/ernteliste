  // ignore_for_file: use_key_in_widget_constructors

  import 'package:flutter/material.dart';
	
  void main() => runApp(MyApp());
	
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'FutureBuilder Tutorial',
        home: FutureBuilderExample(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
	
  Future<String> getValue() async {
    // await Future.delayed(const Duration(seconds: 3));
    return 'Fridays For Future';
  }
	
  class FutureBuilderExample extends StatefulWidget {
    @override
    State<StatefulWidget> createState() {
      return _FutureBuilderExampleState ();
    }
  }
	
  class _FutureBuilderExampleState extends State<FutureBuilderExample> {
    late Future<String> _value;
	
    @override
    initState() {
      super.initState();
      _value = getValue();
    }
	
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FutureBuilder'),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Center(
            child: FutureBuilder<String>(
              future: _value,
              // initialData: 'App Name',
              builder: (
                BuildContext context,
                AsyncSnapshot<String> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      Visibility(
                        visible: snapshot.hasData,
                        child: Text(
                          snapshot.data!,
                          style: const TextStyle(color: Colors.black, fontSize: 24),
                        ),
                      )
                    ],
                  );
                } else if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return const Text('Error');
                  } else if (snapshot.hasData) {
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(color: Colors.teal, fontSize: 36)
                    );
                  } else {
                    return const Text('Empty data');
                  }
                } else {
                  return Text('State: ${snapshot.connectionState}');
                }
              },
            ),
          ),
        ),
      );
    }
	
  }
