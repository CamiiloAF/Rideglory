import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension GoRouterExtensions on BuildContext {
  void goAndClearStack(String routeName) {
    while (canPop()) {
      pop();
    }
    pushReplacementNamed(routeName);
  }
}
