import 'package:flutter/material.dart';

import 'app_nav_scroll_switcher.dart';

/// Wraps an [IndexedStack] with a smooth crossfade + micro-slide animation
/// whenever the active tab changes. Old content gently dims, new content fades
/// in — giving a premium "tab switch" feel without losing widget state.
class AppAnimatedTabBody extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final ValueChanged<int>? onIndexChanged;
  final double dragThreshold;
  final double pointerScrollThreshold;

  const AppAnimatedTabBody({
    super.key,
    required this.currentIndex,
    required this.children,
    this.onIndexChanged,
    this.dragThreshold = 42,
    this.pointerScrollThreshold = 42,
  });

  @override
  State<AppAnimatedTabBody> createState() => _AppAnimatedTabBodyState();
}

class _AppAnimatedTabBodyState extends State<AppAnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late int _displayedIndex;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.currentIndex;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      value: 1.0,
    );
    _buildAnimations();
  }

  void _buildAnimations() {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0.82, end: 1.0).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.010),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didUpdateWidget(covariant AppAnimatedTabBody old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex) {
      setState(() => _displayedIndex = widget.currentIndex);
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(index: _displayedIndex, children: widget.children),
      ),
    );

    final onIndexChanged = widget.onIndexChanged;
    if (onIndexChanged == null) {
      return tabBody;
    }

    return AppNavScrollSwitcher(
      currentIndex: widget.currentIndex,
      itemCount: widget.children.length,
      onIndexChanged: onIndexChanged,
      dragThreshold: widget.dragThreshold,
      pointerScrollThreshold: widget.pointerScrollThreshold,
      child: tabBody,
    );
  }
}
