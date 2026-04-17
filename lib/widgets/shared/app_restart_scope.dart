import 'package:flutter/material.dart';

class AppRestartScope extends StatefulWidget {
  final Widget child;

  const AppRestartScope({super.key, required this.child});

  static void restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRestartScopeState>();
    state?._restart();
  }

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _subtreeKey = UniqueKey();

  void _restart() {
    setState(() {
      _subtreeKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _subtreeKey, child: widget.child);
  }
}
