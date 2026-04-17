import '../l10n/generated/app_localizations.dart';

/// Localized form-field validators.
///
/// Each factory method accepts an [AppLocalizations] instance and returns a
/// `FormFieldValidator<String>` — a closure that validates and returns a
/// localized error string or `null` if the value is valid.
///
/// Usage:
/// ```dart
/// final l10n = AppLocalizations.of(context)!;
/// TextFormField(validator: Validators.fullName(l10n), ...);
/// ```
class Validators {
  Validators._();

  static FormFieldValidator<String> fullName(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return l10n.validationFullNameRequired;
      }
      if (value.trim().length < 2) {
        return l10n.validationNameMinLength;
      }
      return null;
    };
  }

  static FormFieldValidator<String> email(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return l10n.validationEmailRequired;
      }
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return l10n.validationValidEmailAddress;
      }
      return null;
    };
  }

  static FormFieldValidator<String> password(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.isEmpty) {
        return l10n.validationPasswordRequired;
      }
      if (value.length < 8) {
        return l10n.validationPasswordMinLength;
      }
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return l10n.validationPasswordUppercase;
      }
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return l10n.validationPasswordLowercase;
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return l10n.validationPasswordNumber;
      }
      return null;
    };
  }

  static FormFieldValidator<String> loginPassword(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.isEmpty) {
        return l10n.validationPasswordRequired;
      }
      return null;
    };
  }

  static FormFieldValidator<String> confirmPassword(
    AppLocalizations l10n,
    String original,
  ) {
    return (value) {
      if (value == null || value.isEmpty) {
        return l10n.validationConfirmPasswordRequired;
      }
      if (value != original) {
        return l10n.validationPasswordsDoNotMatch;
      }
      return null;
    };
  }

  // Password strength helpers (no localization needed — boolean checks only).
  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  static bool hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  static bool hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);
}
