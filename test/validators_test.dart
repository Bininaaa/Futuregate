import 'package:avenirdz/l10n/generated/app_localizations.dart';
import 'package:avenirdz/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pumps a throwaway MaterialApp and returns the AppLocalizations instance.
Future<AppLocalizations> _getL10n(WidgetTester tester) async {
  AppLocalizations? l10n;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return l10n!;
}

void main() {
  group('Validators.fullName', () {
    testWidgets('returns error for null', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.fullName(l)(null), isNotNull);
    });

    testWidgets('returns error for blank string', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.fullName(l)('   '), isNotNull);
    });

    testWidgets('returns error when name is too short', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.fullName(l)('A'), isNotNull);
    });

    testWidgets('returns null for a valid name', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.fullName(l)('Yasser'), isNull);
    });
  });

  group('Validators.email', () {
    testWidgets('returns error for empty email', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.email(l)(''), isNotNull);
    });

    testWidgets('returns error for email without domain', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.email(l)('user@'), isNotNull);
    });

    testWidgets('returns error for email without @', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.email(l)('userexample.com'), isNotNull);
    });

    testWidgets('returns null for valid email', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.email(l)('user@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    testWidgets('returns error for empty password', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)(''), isNotNull);
    });

    testWidgets('returns error when password too short', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)('Ab1'), isNotNull);
    });

    testWidgets('returns error when no uppercase', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)('abcdefg1'), isNotNull);
    });

    testWidgets('returns error when no lowercase', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)('ABCDEFG1'), isNotNull);
    });

    testWidgets('returns error when no digit', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)('Abcdefgh'), isNotNull);
    });

    testWidgets('returns null for strong password', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.password(l)('Secure1!'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    testWidgets('returns error when confirmation is empty', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.confirmPassword(l, 'Secure1!')(''), isNotNull);
    });

    testWidgets('returns error when passwords do not match', (tester) async {
      final l = await _getL10n(tester);
      expect(
          Validators.confirmPassword(l, 'Secure1!')('Different1!'), isNotNull);
    });

    testWidgets('returns null when passwords match', (tester) async {
      final l = await _getL10n(tester);
      expect(Validators.confirmPassword(l, 'Secure1!')('Secure1!'), isNull);
    });
  });

  group('Validators password-strength helpers', () {
    test('hasMinLength', () {
      expect(Validators.hasMinLength('1234567'), isFalse);
      expect(Validators.hasMinLength('12345678'), isTrue);
    });

    test('hasUppercase', () {
      expect(Validators.hasUppercase('lowercase'), isFalse);
      expect(Validators.hasUppercase('Lowercase'), isTrue);
    });

    test('hasLowercase', () {
      expect(Validators.hasLowercase('UPPER'), isFalse);
      expect(Validators.hasLowercase('Upper'), isTrue);
    });

    test('hasNumber', () {
      expect(Validators.hasNumber('NoNumber'), isFalse);
      expect(Validators.hasNumber('Has1Number'), isTrue);
    });
  });
}
