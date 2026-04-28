import 'package:avenirdz/utils/application_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplicationStatus.parse', () {
    test('defaults missing and unknown values to pending', () {
      expect(ApplicationStatus.parse(null), ApplicationStatus.pending);
      expect(ApplicationStatus.parse(''), ApplicationStatus.pending);
      expect(
        ApplicationStatus.parse('needs_review'),
        ApplicationStatus.pending,
      );
    });

    test('keeps legacy approved status compatible with accepted storage', () {
      expect(ApplicationStatus.parse('approved'), ApplicationStatus.accepted);
      expect(ApplicationStatus.parse('accepted'), ApplicationStatus.accepted);
    });
  });
}
