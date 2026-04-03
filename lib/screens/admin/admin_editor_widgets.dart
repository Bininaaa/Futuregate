import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/admin_palette.dart';
import '../../widgets/admin/admin_ui.dart';

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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
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
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(submitLabel),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminEditorSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AdminEditorSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.6,
              color: AdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class AdminEditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const AdminEditorField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AdminPalette.textPrimary,
          ),
          decoration: adminEditorFieldDecoration(
            hint: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AdminPalette.textPrimary,
          ),
          decoration: adminEditorFieldDecoration(hint: label),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AdminPalette.textSecondary,
          ),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AdminPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : AdminPalette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? color : AdminPalette.textMuted,
                size: 20,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 1.45,
                  color: selected ? color : AdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: AdminPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminPalette.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AdminPalette.primary,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            height: 1.45,
            color: AdminPalette.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

InputDecoration adminEditorFieldDecoration({
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(
      fontSize: 12.5,
      color: AdminPalette.textMuted,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AdminPalette.surfaceMuted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AdminPalette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AdminPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AdminPalette.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1.4),
    ),
  );
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
