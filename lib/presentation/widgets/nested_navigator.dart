import 'package:flutter/material.dart';

class NestedNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget home;
  final RouteFactory? onGenerateRoute;

  const NestedNavigator({
    super.key,
    required this.navigatorKey,
    required this.home,
    this.onGenerateRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => home,
            settings: settings,
          );
        }
        return onGenerateRoute?.call(settings) ??
            MaterialPageRoute(
              builder: (_) => const Center(child: Text('Unknown Route')),
            );
      },
    );
  }
}
