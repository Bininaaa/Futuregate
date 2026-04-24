import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Records a non-fatal error to Crashlytics in release builds.
/// In debug mode it just prints so the test suite stays clean.
void recordNonFatal(
  Object error,
  StackTrace stack, {
  required String context,
}) {
  if (kDebugMode) {
    debugPrint('[$context] $error');
    return;
  }
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: context,
    fatal: false,
  );
}
