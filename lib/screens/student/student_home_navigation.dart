import 'package:flutter/material.dart';

class StudentHomeNavigation {
  StudentHomeNavigation._();

  static const int homeTab = 0;
  static const int discoverTab = 1;
  static const int scholarshipsTab = 2;
  static const int trainingTab = 3;
  static const int ideasTab = 4;
  static const int chatTab = 5;

  static final ValueNotifier<int?> requestedTabIndex = ValueNotifier<int?>(
    null,
  );
  static final ValueNotifier<String?> requestedDiscoverFilter =
      ValueNotifier<String?>(null);

  static void switchToTab(
    BuildContext context,
    int index, {
    String? discoverFilter,
  }) {
    requestedDiscoverFilter.value = index == discoverTab
        ? discoverFilter
        : null;
    requestedTabIndex.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void switchToDiscover(BuildContext context, {String? filter}) {
    switchToTab(context, discoverTab, discoverFilter: filter);
  }

  static String? takeRequestedDiscoverFilter() {
    final filter = requestedDiscoverFilter.value;
    requestedDiscoverFilter.value = null;
    return filter;
  }
}
