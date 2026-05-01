import 'package:avenirdz/models/premium_config_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal student saved opportunity limit is capped at eight', () {
    final config = PremiumConfigModel.fromMap({'freeSavedItemsLimit': 10});

    expect(config.freeSavedLimit, 10);
    expect(config.effectiveFreeSavedLimit, 8);
  });
}
