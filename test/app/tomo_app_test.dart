import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/l10n/app_localizations.dart';

void main() {
  testWidgets('the app starts and shows an empty screen', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app name comes from the copy files', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(AppLocalizations.of(context).appName, 'Tomo');
    expect(tester.widget<Title>(find.byType(Title)).title, 'Tomo');
  });
}
