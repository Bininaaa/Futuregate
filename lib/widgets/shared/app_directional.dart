import 'package:flutter/material.dart';

bool appShouldMirrorIcon(IconData icon) {
  return icon == Icons.arrow_back ||
      icon == Icons.arrow_back_ios ||
      icon == Icons.arrow_back_ios_new ||
      icon == Icons.arrow_back_rounded ||
      icon == Icons.arrow_forward ||
      icon == Icons.arrow_forward_ios ||
      icon == Icons.arrow_forward_ios_rounded ||
      icon == Icons.arrow_forward_rounded ||
      icon == Icons.chevron_left ||
      icon == Icons.chevron_left_rounded ||
      icon == Icons.chevron_right ||
      icon == Icons.chevron_right_rounded ||
      icon == Icons.keyboard_arrow_left ||
      icon == Icons.keyboard_arrow_left_rounded ||
      icon == Icons.keyboard_arrow_right ||
      icon == Icons.keyboard_arrow_right_rounded;
}

class AppDirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AppDirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final renderedIcon = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

    if (!appShouldMirrorIcon(icon) ||
        Directionality.maybeOf(context) != TextDirection.rtl) {
      return renderedIcon;
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
      child: renderedIcon,
    );
  }
}

class AppInlineIconLabel extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final Widget label;
  final double iconSize;
  final Color? iconColor;
  final double gap;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const AppInlineIconLabel({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.iconSize = 16,
    this.iconColor,
    this.gap = 6,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLeading =
        leading ??
        (icon == null
            ? null
            : AppDirectionalIcon(icon!, size: iconSize, color: iconColor));

    return Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        if (effectiveLeading != null) ...<Widget>[
          effectiveLeading,
          SizedBox(width: gap),
        ],
        label,
      ],
    );
  }
}
