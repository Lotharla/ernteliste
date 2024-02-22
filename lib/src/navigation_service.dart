import 'package:ernteliste/src/app_constant.dart';
import 'package:flutter/material.dart';

class NavigationService {
  /// Creating the first instance
  static final NavigationService _instance = NavigationService._internal();
  NavigationService._internal();

  /// With this factory setup, any time  NavigationService() is called
  /// within the appication _instance will be returned and not a new instance
  factory NavigationService() => _instance;

  ///This would allow the app monitor the current screen state during navigation.
  ///
  ///This is where the singleton setup we did
  ///would help as the state is internally maintained
  final GlobalKey<NavigatorState> navigatorKey = AppConstant.globalNavigatorKey;

  /// For navigating back to the previous screen
  dynamic goBack([dynamic popValue]) {
    return navigatorKey.currentState!.pop(popValue);
  }

  /// This allows you to naviagte to the next screen by passing the screen widget
  Future<dynamic> navigateToScreen(Widget page, {arguments}) async => navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => page,
          settings: RouteSettings(arguments: arguments),
        ),
      );

  /// This allows you to naviagte to the next screen and
  /// also replace the current screen by passing the screen widget
  Future<dynamic> replaceScreen(Widget page, {arguments}) async => navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (_) => page,
          settings: RouteSettings(arguments: arguments),
        ),
      );

  /// Allows you to pop to the first screen to when the app first launched.
  /// This is useful when you need to log out a user,
  /// and also remove all the screens on the navigation stack.
  /// I find this very useful
  void popToFirst() => navigatorKey.currentState!.popUntil((route) => route.isFirst);

  Future<void> navigateAndDisplayResult(BuildContext context, Widget page, {arguments}) async {
    var messenger = ScaffoldMessenger.of(context);
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the page.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
    );

    // When a BuildContext is used from a StatefulWidget, the mounted property
    // must be checked after an asynchronous gap.
    // if (!mounted) return;

    // After the Selection Screen returns a result, hide any previous snackbars
    // and show the new result.
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$result')));
  }
}
