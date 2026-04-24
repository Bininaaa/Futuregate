import 'package:avenirdz/widgets/shared/app_content_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppEditableListField shows an item committed with Enter', (
    tester,
  ) async {
    var values = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppEditableListField(
                theme: AppContentTheme.futureGate(),
                label: '',
                hint: 'Type one requirement, then press Enter',
                values: values,
                onChanged: (items) => setState(() => values = items),
                splitOnCommas: false,
                emptyText: '',
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Portfolio link');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(values, <String>['Portfolio link']);
    expect(find.text('Portfolio link'), findsOneWidget);
  });
}
