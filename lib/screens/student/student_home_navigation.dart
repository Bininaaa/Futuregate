import 'package:flutter/material.dart';

class StudentHomeNavigation {
  StudentHomeNavigation._();

  static const int homeTab = 0;
  static const int discoverTab = 1;

  static final ValueNotifier<int?> requestedTabIndex = ValueNotifier<int?>(
    null,
  );

  static void switchToTab(BuildContext context, int index) {
    requestedTabIndex.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
