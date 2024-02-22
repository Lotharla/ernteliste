// This is an example Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
//
// Visit https://flutter.dev/docs/cookbook/testing/widget/introduction for
// more information about Widget testing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server/utils.dart';

import 'apps/persisting.dart' as persisting;
import 'apps/navigating.dart' as navigating;

class MyWidget extends StatelessWidget {
  const MyWidget({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}
void main() {
  group('MyWidget', () {
    testWidgets('has a title and message', (tester) async {
      await tester.pumpWidget(const MyWidget(title: 'T', message: 'M'));
      final titleFinder = find.text('T');
      final messageFinder = find.text('M');

      // Use the `findsOneWidget` matcher provided by flutter_test to verify
      // that the Text widgets appear exactly once in the widget tree.
      expect(titleFinder, findsOneWidget);
      expect(messageFinder, findsOneWidget);
    });
    testWidgets('should display a string of text', (WidgetTester tester) async {
      // Define a Widget
      const myWidget = MaterialApp(
        home: Scaffold(
          body: Text('Hello'),
        ),
      );

      // Build myWidget and trigger a frame.
      await tester.pumpWidget(myWidget);

      // Verify myWidget shows some text
      expect(find.byType(Text), findsNWidgets(1));
    });
  });
  group('MyApp', () {
    testWidgets('persisting should display a map', (WidgetTester tester) async {
      await tester.pumpWidget(const persisting.MyApp());
      var finder = find.text('{}');
      expect(finder, findsOneWidget);
      // Tap the floating button.
      await tester.tap(find.byType(FloatingActionButton));
      // Rebuild the widget with the new item.
      await tester.pump();
      // Expect to find the item on screen.
      finder = find.textContaining(kwRegExp());
      expect(finder, findsOneWidget);
    });
    testWidgets('routing should display buttons', (WidgetTester tester) async {
      var myApp = await navigating.main();
      await tester.pumpWidget(myApp);
      expect(find.byType(ElevatedButton), findsAtLeast(4));
      var finder = find.textContaining('ErtragForm');
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump();
      // Expect to find the item on screen.
      finder = find.textContaining(kwRegExp());
      expect(finder, findsOneWidget);
    });
 });
}
