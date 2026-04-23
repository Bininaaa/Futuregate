import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppNavScrollSwitcher extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final int itemCount;
  final ValueChanged<int> onIndexChanged;
  final double dragThreshold;
  final double pointerScrollThreshold;

  const AppNavScrollSwitcher({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.itemCount,
    required this.onIndexChanged,
    this.dragThreshold = 28,
    this.pointerScrollThreshold = 18,
  });

  @override
  State<AppNavScrollSwitcher> createState() => _AppNavScrollSwitcherState();
}

class _AppNavScrollSwitcherState extends State<AppNavScrollSwitcher> {
  static const Duration _pointerSwitchCooldown = Duration(milliseconds: 180);

  double _dragOffset = 0;
  double _pointerScrollOffset = 0;
  DateTime? _lastPointerSwitchAt;

  void _stepTo(int direction) {
    if (widget.itemCount <= 1) {
      return;
    }

    final nextIndex = (widget.currentIndex + direction).clamp(
      0,
      widget.itemCount - 1,
    );
    if (nextIndex == widget.currentIndex) {
      return;
    }

    widget.onIndexChanged(nextIndex);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragOffset = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final travelledFarEnough = _dragOffset.abs() >= widget.dragThreshold;
    final movedFastEnough = velocity.abs() >= 220;

    if (!travelledFarEnough && !movedFastEnough) {
      _dragOffset = 0;
      return;
    }

    final direction = _dragOffset < 0 || velocity < 0 ? 1 : -1;
    _dragOffset = 0;
    _stepTo(direction);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || widget.itemCount <= 1) {
      return;
    }

    final lastPointerSwitchAt = _lastPointerSwitchAt;
    final now = DateTime.now();
    if (lastPointerSwitchAt != null &&
        now.difference(lastPointerSwitchAt) < _pointerSwitchCooldown) {
      return;
    }

    final deltaX = event.scrollDelta.dx;
    final deltaY = event.scrollDelta.dy;
    final dominantDelta = deltaX.abs() > deltaY.abs() ? deltaX : deltaY;

    if (dominantDelta == 0) {
      return;
    }

    _pointerScrollOffset += dominantDelta;
    if (_pointerScrollOffset.abs() < widget.pointerScrollThreshold) {
      return;
    }

    final direction = _pointerScrollOffset > 0 ? 1 : -1;
    _pointerScrollOffset = 0;
    _lastPointerSwitchAt = now;
    _stepTo(direction);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: widget.child,
      ),
    );
  }
}
