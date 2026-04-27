import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../utils/display_text.dart';
import 'app_feedback.dart';

enum AppContentTypography { product, innovation }

class AppContentTheme {
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;
  final Gradient heroGradient;
  final AppContentTypography typography;

  const AppContentTheme({
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.heroGradient,
    this.typography = AppContentTypography.product,
  });

  factory AppContentTheme.futureGate({
    Color? accent,
    Color? accentDark,
    Color? accentSoft,
    Color? secondary,
    Gradient? heroGradient,
    AppContentTypography typography = AppContentTypography.product,
  }) {
    final colors = AppColors.current;

    return AppContentTheme(
      accent: accent ?? colors.primary,
      accentDark: accentDark ?? colors.primaryDeep,
      accentSoft: accentSoft ?? colors.primarySoft,
      secondary: secondary ?? colors.secondary,
      background: colors.background,
      surface: colors.surface,
      surfaceMuted: colors.surfaceMuted,
      border: colors.border,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      textMuted: colors.textMuted,
      success: colors.success,
      warning: colors.warning,
      error: colors.danger,
      heroGradient:
          heroGradient ?? colors.heroGradient(accent ?? colors.secondary),
      typography: typography,
    );
  }

  TextStyle headline({
    double size = 26,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    switch (typography) {
      case AppContentTypography.innovation:
        return AppTypography.innovationTitle(
          fontSize: size,
          fontWeight: weight,
          height: 1.06,
          color: color ?? textPrimary,
        );
      case AppContentTypography.product:
        return AppTypography.product(
          fontSize: size,
          fontWeight: weight,
          height: 1.1,
          color: color ?? textPrimary,
        );
    }
  }

  TextStyle section({
    double size = 17,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    switch (typography) {
      case AppContentTypography.innovation:
        return AppTypography.innovationTitle(
          fontSize: size,
          fontWeight: weight,
          height: 1.12,
          color: color ?? textPrimary,
        );
      case AppContentTypography.product:
        return AppTypography.product(
          fontSize: size,
          fontWeight: weight,
          height: 1.16,
          color: color ?? textPrimary,
        );
    }
  }

  TextStyle body({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.55,
  }) {
    switch (typography) {
      case AppContentTypography.innovation:
        return AppTypography.innovationBody(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? textSecondary,
        );
      case AppContentTypography.product:
        return AppTypography.product(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? textSecondary,
        );
    }
  }

  TextStyle label({
    double size = 12.5,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    switch (typography) {
      case AppContentTypography.innovation:
        return AppTypography.innovationBody(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: 0.12,
          color: color ?? textPrimary,
        );
      case AppContentTypography.product:
        return AppTypography.product(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: 0.08,
          color: color ?? textPrimary,
        );
    }
  }

  TextStyle eyebrow({Color? color}) {
    return label(
      size: 10.5,
      color: color ?? textMuted,
      weight: FontWeight.w600,
    ).copyWith(letterSpacing: 0.6);
  }

  List<BoxShadow> shadow([double opacity = 0.06]) {
    return <BoxShadow>[
      BoxShadow(
        color: accent.withValues(alpha: opacity),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: AppColors.current.shadow.withValues(
          alpha: AppColors.isDark ? opacity * 2.2 : opacity * 0.65,
        ),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];
  }

  AppContentTheme copyWithAccent(Color nextAccent, {Color? nextAccentDark}) {
    return AppContentTheme(
      accent: nextAccent,
      accentDark: nextAccentDark ?? accentDark,
      accentSoft: accentSoft,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceMuted: surfaceMuted,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      success: success,
      warning: warning,
      error: error,
      heroGradient: heroGradient,
      typography: typography,
    );
  }
}

class AppContentSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24;

  const AppContentSpacing._();
}

class AppBadgeData {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  const AppBadgeData({
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  });
}

class AppInfoTileData {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;
  final Color? color;

  const AppInfoTileData({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
    this.color,
  });
}

InputDecoration _fieldDecoration({
  required AppContentTheme theme,
  required String hint,
  Widget? suffixIcon,
}) {
  const fieldRadius = 20.0;
  return InputDecoration(
    hintText: hint,
    hintStyle: theme.body(size: 12.5, color: theme.textMuted),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: theme.surfaceMuted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: theme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: theme.accent, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: theme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: theme.error, width: 1.4),
    ),
    errorStyle: AppTypography.product(
      fontSize: 11.6,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: theme.error,
    ),
    errorMaxLines: 3,
  );
}

class AppFormHeaderCard extends StatelessWidget {
  final AppContentTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<AppBadgeData> badges;
  final Widget? footer;

  const AppFormHeaderCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badges = const <AppBadgeData>[],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppContentSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[theme.accentSoft, theme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppContentSpacing.xxl),
        border: Border.all(color: theme.border),
        boxShadow: theme.shadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[theme.accent, theme.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppContentSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.section(size: 18)),
                    const SizedBox(height: AppContentSpacing.xs),
                    Text(subtitle, style: theme.body(size: 12.4)),
                  ],
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            Wrap(
              spacing: AppContentSpacing.xs,
              runSpacing: AppContentSpacing.xs,
              children: badges
                  .map((badge) => AppTagChip(theme: theme, badge: badge))
                  .toList(growable: false),
            ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

class AppFormSectionCard extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final String? subtitle;
  final Widget child;

  const AppFormSectionCard({
    super.key,
    required this.theme,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle?.trim();
    final hasSubtitle = subtitleText != null && subtitleText.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppContentSpacing.md),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppContentSpacing.xxl),
        border: Border.all(color: theme.border),
        boxShadow: theme.shadow(0.035),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.section(size: 15.5)),
          if (hasSubtitle) ...[
            const SizedBox(height: AppContentSpacing.xs),
            Text(subtitleText, style: theme.body(size: 12.2)),
          ],
          const SizedBox(height: AppContentSpacing.md),
          child,
        ],
      ),
    );
  }
}

class AppFormField extends StatelessWidget {
  final AppContentTheme theme;
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int? minLength;
  final String? helperText;

  const AppFormField({
    super.key,
    required this.theme,
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.onChanged,
    this.minLength,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final showLabel = label.trim().isNotEmpty;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final minimum = minLength ?? 0;
        final currentLength = controller.text.trim().length;
        final showCounter = minimum > 0;
        final helper = helperText?.trim() ?? '';
        final meetsMinimum = !showCounter || currentLength >= minimum;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showLabel) Text(label, style: theme.label(size: 12)),
            if (showLabel) const SizedBox(height: AppContentSpacing.xs),
            TextFormField(
              controller: controller,
              minLines: minLines,
              maxLines: maxLines,
              validator: validator,
              autovalidateMode: autovalidateMode,
              keyboardType: keyboardType,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: theme.body(
                color: theme.textPrimary,
                weight: FontWeight.w500,
              ),
              decoration: _fieldDecoration(
                theme: theme,
                hint: hint,
                suffixIcon: suffixIcon,
              ),
            ),
            if (helper.isNotEmpty || showCounter) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (helper.isNotEmpty)
                    Expanded(
                      child: Text(
                        helper,
                        style: theme.body(
                          size: 11.5,
                          height: 1.35,
                          color: theme.textSecondary,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (showCounter) ...[
                    if (helper.isNotEmpty) const SizedBox(width: 12),
                    Text(
                      '$currentLength/$minimum',
                      style: theme.label(
                        size: 11.2,
                        weight: FontWeight.w700,
                        color: meetsMinimum ? theme.success : theme.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class AppFormDropdownField<T> extends StatelessWidget {
  final AppContentTheme theme;
  final T? value;
  final String label;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppFormDropdownField({
    super.key,
    required this.theme,
    required this.value,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.label(size: 12)),
        const SizedBox(height: AppContentSpacing.xs),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: theme.surface,
          style: theme.body(color: theme.textPrimary, weight: FontWeight.w500),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.textSecondary,
          ),
          decoration: _fieldDecoration(theme: theme, hint: hint),
        ),
      ],
    );
  }
}

class AppEditableListController {
  final TextEditingController _textController = TextEditingController();
  _AppEditableListFieldState? _state;

  bool commitPendingInput() => _state?._commitPendingInput() ?? false;

  void dispose() {
    _textController.dispose();
  }
}

class AppEditableListField extends StatefulWidget {
  final AppContentTheme theme;
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final AppEditableListController? listController;
  final String? Function(List<String>)? validator;
  final List<String> examples;
  final String emptyText;
  final IconData addIcon;
  final bool splitOnCommas;

  const AppEditableListField({
    super.key,
    required this.theme,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.listController,
    this.validator,
    this.examples = const <String>[],
    this.emptyText = 'Add each item one by one.',
    this.addIcon = Icons.add_circle_outline_rounded,
    this.splitOnCommas = true,
  });

  @override
  State<AppEditableListField> createState() => _AppEditableListFieldState();
}

class _AppEditableListFieldState extends State<AppEditableListField> {
  late AppEditableListController _controller;
  late final FocusNode _inputFocusNode;
  FormFieldState<List<String>>? _fieldState;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode = FocusNode(onKeyEvent: _handleInputKeyEvent);
    _attachController(widget.listController);
  }

  @override
  void didUpdateWidget(covariant AppEditableListField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listController != widget.listController) {
      _detachController();
      _attachController(widget.listController);
    }
  }

  @override
  void dispose() {
    _detachController();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _attachController(AppEditableListController? controller) {
    _controller = controller ?? AppEditableListController();
    _ownsController = controller == null;
    _controller._state = this;
  }

  void _detachController() {
    if (_controller._state == this) {
      _controller._state = null;
    }
    if (_ownsController) {
      _controller.dispose();
    }
  }

  KeyEventResult _handleInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }

    _commitPendingInput();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: widget.values,
      validator: (value) => widget.validator?.call(value ?? widget.values),
      builder: (field) {
        _fieldState = field;
        final showLabel = widget.label.trim().isNotEmpty;
        final showEmptyText = widget.emptyText.trim().isNotEmpty;
        final currentValues = field.value ?? widget.values;

        void removeItem(String item) {
          final next = currentValues
              .where(
                (value) =>
                    value.trim().toLowerCase() != item.trim().toLowerCase(),
              )
              .toList(growable: false);
          widget.onChanged(next);
          field.didChange(next);
        }

        void addExample(String item) {
          final next = _mergeUnique(currentValues, <String>[item]);
          widget.onChanged(next);
          field.didChange(next);
        }

        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showLabel)
              Text(widget.label, style: widget.theme.label(size: 12)),
            if (showLabel) const SizedBox(height: AppContentSpacing.xs),
            if (currentValues.isEmpty && showEmptyText)
              Text(
                widget.emptyText,
                style: widget.theme.body(
                  size: 11.8,
                  color: widget.theme.textMuted,
                ),
              )
            else if (currentValues.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentValues
                        .map(
                          (item) => _AppEditableListChip(
                            theme: widget.theme,
                            label: item,
                            maxWidth: constraints.maxWidth,
                            onRemove: () => removeItem(item),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            const SizedBox(height: AppContentSpacing.sm),
            TextFormField(
              controller: _controller._textController,
              focusNode: _inputFocusNode,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.multiline,
              onFieldSubmitted: (_) => _commitPendingInput(field),
              style: widget.theme.body(
                color: widget.theme.textPrimary,
                weight: FontWeight.w500,
              ),
              decoration: _fieldDecoration(
                theme: widget.theme,
                hint: widget.hint,
                suffixIcon: IconButton(
                  tooltip: 'Add item',
                  icon: Icon(widget.addIcon, color: widget.theme.accent),
                  onPressed: () => _commitPendingInput(field),
                ),
              ),
            ),
            if (widget.examples.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppContentSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.examples
                    .map(
                      (example) => _AppExampleChip(
                        theme: widget.theme,
                        label: example,
                        onTap: () => addExample(example),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (hasError) ...<Widget>[
              const SizedBox(height: AppContentSpacing.xs),
              Text(
                field.errorText ?? '',
                style: AppTypography.product(
                  fontSize: 11.6,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: widget.theme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _commitPendingInput([FormFieldState<List<String>>? field]) {
    final fieldState = field ?? _fieldState;
    final additions = _parseListItems(_controller._textController.text);
    if (additions.isEmpty) {
      fieldState?.validate();
      return false;
    }

    final next = _mergeUnique(fieldState?.value ?? widget.values, additions);
    widget.onChanged(next);
    fieldState?.didChange(next);
    _controller._textController.clear();
    return true;
  }

  List<String> _parseListItems(String rawValue) {
    final normalized = rawValue
        .replaceAll('\r', '\n')
        .replaceAll('\u2022', '\n')
        .trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    return normalized
        .split(
          widget.splitOnCommas
              ? RegExp(r'\n+|;|(?<!\d),(?!\d)')
              : RegExp(r'\n+|;'),
        )
        .map(_cleanListItem)
        .whereType<String>()
        .toList(growable: false);
  }

  List<String> _mergeUnique(List<String> current, List<String> additions) {
    final seen = <String>{};
    final next = <String>[];

    for (final item in <String>[...current, ...additions]) {
      final cleaned = _cleanListItem(item);
      if (cleaned == null) {
        continue;
      }

      if (seen.add(cleaned.toLowerCase())) {
        next.add(cleaned);
      }
    }

    return next;
  }

  String? _cleanListItem(String value) {
    final cleaned = value
        .replaceFirst(RegExp(r'^\s*[-*]+\s*'), '')
        .replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}

class _AppEditableListChip extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final double maxWidth;
  final VoidCallback onRemove;

  const _AppEditableListChip({
    required this.theme,
    required this.label,
    required this.maxWidth,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.accent.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: theme.body(
                    size: 11.6,
                    color: theme.accentDark,
                    weight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: theme.accentDark.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppExampleChip extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final VoidCallback onTap;

  const _AppExampleChip({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: widgetSurfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.add_rounded, size: 13, color: theme.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.body(
                  size: 10.9,
                  color: theme.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get widgetSurfaceColor => theme.surfaceMuted.withValues(alpha: 0.72);
}

class AppChoiceCard extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const AppChoiceCard({
    super.key,
    required this.theme,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? theme.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.1)
                : theme.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : theme.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: selected ? accent : theme.textMuted, size: 18),
              const SizedBox(height: AppContentSpacing.sm),
              Text(
                label,
                style: theme.label(
                  size: 12.2,
                  color: selected ? accent : theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.body(
                  size: 11.1,
                  color: selected
                      ? accent.withValues(alpha: 0.86)
                      : theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppChoiceWrap extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const AppChoiceWrap({
    super.key,
    required this.theme,
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.label(size: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map((value) {
                final isSelected = selectedValue == value;
                return _AppSelectorChip(
                  theme: theme,
                  label: value,
                  selected: isSelected,
                  trailingIcon: isSelected ? Icons.check_rounded : null,
                  onTap: () => onSelected(value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class AppChipSelector extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final List<String> suggestions;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  const AppChipSelector({
    super.key,
    required this.theme,
    required this.title,
    required this.suggestions,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final orderedValues = <String>[
      ...suggestions,
      ...selectedValues.where((value) => !suggestions.contains(value)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.label(size: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: orderedValues
              .map((value) {
                final isSelected = selectedValues.contains(value);
                return _AppSelectorChip(
                  theme: theme,
                  label: value,
                  selected: isSelected,
                  trailingIcon: isSelected ? Icons.close_rounded : null,
                  onTap: () => onToggle(value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _AppSelectorChip extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final bool selected;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _AppSelectorChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.accent;
    final hasTrailingIcon = trailingIcon != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            left: 12,
            right: hasTrailingIcon ? 6 : 12,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.08)
                : theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.15)
                  : theme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.body(
                  size: 11.5,
                  weight: FontWeight.w500,
                  height: 1.45,
                  color: selected ? accentColor : theme.textPrimary,
                ),
              ),
              if (hasTrailingIcon) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  trailingIcon,
                  size: 16,
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSwitchTileCard extends StatelessWidget {
  final AppContentTheme theme;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const AppSwitchTileCard({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.accent,
        activeTrackColor: theme.accent.withValues(alpha: 0.24),
        title: Text(title, style: theme.label(size: 12.4)),
        subtitle: Text(subtitle, style: theme.body(size: 12)),
      ),
    );
  }
}

class AppInfoHint extends StatelessWidget {
  final AppContentTheme theme;
  final IconData icon;
  final String title;
  final String message;

  const AppInfoHint({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppInlineMessage(
      type: AppFeedbackType.info,
      title: title,
      message: message,
      icon: icon,
      accentColor: theme.accent,
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;

  const AppPrimaryButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.accent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : icon == null
            ? const SizedBox.shrink()
            : Icon(icon, size: 17),
        label: Text(label, style: theme.label(size: 13, color: Colors.white)),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textPrimary,
          side: BorderSide(color: theme.border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 17),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: theme.label(size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDetailHeroCard extends StatelessWidget {
  final AppContentTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? summary;
  final List<AppBadgeData> badges;
  final Widget? leading;
  final bool showLeading;
  final Widget? footer;
  final String? imageUrl;
  final Widget? media;

  const AppDetailHeroCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.summary,
    this.badges = const <AppBadgeData>[],
    this.leading,
    this.showLeading = true,
    this.footer,
    this.imageUrl,
    this.media,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim() ?? '';
    final hasImage = image.isNotEmpty;
    final headerLeading = showLeading
        ? (leading ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[theme.accent, theme.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ))
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppContentSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[theme.accentSoft, theme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppContentSpacing.xxl),
        border: Border.all(color: theme.border),
        boxShadow: theme.shadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (headerLeading != null) ...<Widget>[
                headerLeading,
                const SizedBox(width: AppContentSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DisplayText.capitalizeDisplayValue(title),
                      style: theme.headline(size: 21.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DisplayText.capitalizeDisplayValue(subtitle),
                      style: theme.body(size: 12.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((summary ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            Text(
              DisplayText.capitalizeDisplayValue(summary!),
              style: theme.body(
                size: 12.6,
                color: theme.textPrimary,
                weight: FontWeight.w500,
              ),
            ),
          ],
          if (badges.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            Wrap(
              spacing: AppContentSpacing.xs,
              runSpacing: AppContentSpacing.xs,
              children: badges
                  .map((badge) => AppTagChip(theme: theme, badge: badge))
                  .toList(growable: false),
            ),
          ],
          if (media != null || hasImage) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            if (media != null)
              ClipRRect(borderRadius: BorderRadius.circular(18), child: media!)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  image,
                  height: 168,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 168,
                    color: theme.surfaceMuted,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.textMuted,
                    ),
                  ),
                ),
              ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppContentSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

class AppInfoTileGrid extends StatelessWidget {
  final AppContentTheme theme;
  final List<AppInfoTileData> items;

  const AppInfoTileGrid({super.key, required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 700
            ? 2
            : 3;

        return GridView.builder(
          itemCount: visibleItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppContentSpacing.sm,
            crossAxisSpacing: AppContentSpacing.sm,
            mainAxisExtent: crossAxisCount == 1 ? 82 : 84,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return AppInfoTile(theme: theme, item: item);
          },
        );
      },
    );
  }
}

class AppInfoTile extends StatelessWidget {
  final AppContentTheme theme;
  final AppInfoTileData item;

  const AppInfoTile({super.key, required this.theme, required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.color ?? theme.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: item.emphasize
            ? theme.accentSoft.withValues(alpha: 0.72)
            : theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.emphasize ? accent.withValues(alpha: 0.22) : theme.border,
        ),
        boxShadow: theme.shadow(item.emphasize ? 0.04 : 0.025),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 14, color: accent),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  DisplayText.capitalizeDisplayValue(item.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.label(
                    size: 11.1,
                    color: theme.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            DisplayText.capitalizeDisplayValue(item.value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.body(
              size: 11.8,
              color: theme.textPrimary,
              weight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDetailSection extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  const AppDetailSection({
    super.key,
    required this.theme,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppContentSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppContentSpacing.xl),
        border: Border.all(color: theme.border),
        boxShadow: theme.shadow(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: theme.accent),
              ),
              const SizedBox(width: AppContentSpacing.sm),
              Expanded(
                child: Text(
                  DisplayText.capitalizeDisplayValue(title),
                  style: theme.section(size: 14.2),
                ),
              ),
            ],
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppContentSpacing.xs),
            Text(
              DisplayText.capitalizeDisplayValue(subtitle!),
              style: theme.body(size: 11.8),
            ),
          ],
          const SizedBox(height: AppContentSpacing.md),
          child,
        ],
      ),
    );
  }
}

class AppTagChip extends StatelessWidget {
  final AppContentTheme theme;
  final AppBadgeData badge;

  const AppTagChip({super.key, required this.theme, required this.badge});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = badge.color ?? theme.accent;
    final backgroundColor =
        badge.backgroundColor ?? foregroundColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (badge.icon != null) ...<Widget>[
            Icon(badge.icon, size: 13, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            DisplayText.capitalizeDisplayValue(badge.label),
            style: theme.label(size: 10.8, color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class AppMetaRow extends StatelessWidget {
  final AppContentTheme theme;
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const AppMetaRow({
    super.key,
    required this.theme,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedColor = color ?? theme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppContentSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: resolvedColor),
            ),
            const SizedBox(width: AppContentSpacing.xs),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.body(size: 12.2, color: theme.textSecondary),
                children: <InlineSpan>[
                  TextSpan(
                    text: '${DisplayText.capitalizeDisplayValue(label)}: ',
                    style: theme.label(size: 11.5, color: theme.textMuted),
                  ),
                  TextSpan(
                    text: DisplayText.capitalizeDisplayValue(value),
                    style: theme.body(
                      size: 12.2,
                      color: theme.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppEmptyFieldPlaceholder extends StatelessWidget {
  final AppContentTheme theme;
  final String text;

  const AppEmptyFieldPlaceholder({
    super.key,
    required this.theme,
    this.text = 'Not provided',
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.body(
        size: 12.2,
        color: theme.textMuted,
        weight: FontWeight.w500,
      ),
    );
  }
}
