import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_content_system.dart';

AppContentTheme get _adminFormTheme => AppContentTheme.futureGate(
  accent: AdminPalette.primary,
  accentDark: AdminPalette.primaryDark,
  accentSoft: AdminPalette.primarySoft,
  secondary: AdminPalette.secondary,
  heroGradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AdminPalette.primaryDark,
      AdminPalette.primary,
      AdminPalette.secondary,
    ],
  ),
);

class AdminEditorScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String submitLabel;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Widget child;

  const AdminEditorScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.submitLabel,
    required this.isSubmitting,
    required this.onSubmit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.product(
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        backgroundColor: AdminPalette.surface,
        foregroundColor: AdminPalette.textPrimary,
      ),
      body: AdminShellBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                AdminSurface(
                  radius: 28,
                  gradient: AdminPalette.heroGradient(accentColor),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.product(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: AppTypography.product(
                                fontSize: 13,
                                height: 1.6,
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            boxShadow: [
              BoxShadow(
                color: AdminPalette.isDark
                    ? AdminPalette.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -12),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AdminPalette.border.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: AppPrimaryButton(
            theme: _adminFormTheme.copyWithAccent(accentColor),
            label: submitLabel,
            onPressed: isSubmitting ? null : onSubmit,
            icon: Icons.check_circle_outline_rounded,
            isBusy: isSubmitting,
          ),
        ),
      ),
    );
  }
}

class AdminEditorSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const AdminEditorSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      theme: _adminFormTheme,
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}

class AdminEditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int? minLength;
  final String? helperText;

  const AdminEditorField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.minLength,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormField(
      theme: _adminFormTheme,
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: autovalidateMode,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      minLength: minLength,
      helperText: helperText,
    );
  }
}

class AdminEditorDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AdminEditorDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormDropdownField<T>(
      theme: _adminFormTheme,
      value: value,
      label: label,
      hint: label,
      items: items,
      onChanged: onChanged,
    );
  }
}

class AdminEditorListField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final AppEditableListController? listController;
  final String? Function(List<String>)? validator;
  final List<String> examples;
  final String emptyText;
  final bool splitOnCommas;

  const AdminEditorListField({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.listController,
    this.validator,
    this.examples = const <String>[],
    this.emptyText = 'Add each item one by one.',
    this.splitOnCommas = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppEditableListField(
      theme: _adminFormTheme,
      label: label,
      hint: hint,
      values: values,
      onChanged: onChanged,
      listController: listController,
      validator: validator,
      examples: examples,
      emptyText: emptyText,
      splitOnCommas: splitOnCommas,
    );
  }
}

class AdminEditorChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const AdminEditorChoiceCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppChoiceCard(
      theme: _adminFormTheme,
      label: label,
      subtitle: subtitle,
      selected: selected,
      color: color,
      icon: icon,
      onTap: onTap,
    );
  }
}

class AdminEditorToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const AdminEditorToggleCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppSwitchTileCard(
      theme: _adminFormTheme,
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
    );
  }
}

String? Function(String?) adminRequiredMin(String label, {int min = 1}) {
  return (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$label is required';
    }
    if (text.length < min) {
      return '$label needs a bit more detail';
    }
    return null;
  };
}

List<String> adminSplitCsv(String value) {
  return value
      .replaceAll('\n', ',')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String adminJoinList(List<String> items) => items.join(', ');

String adminTitleCase(String rawValue) {
  return rawValue
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
