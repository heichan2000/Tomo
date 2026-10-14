import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/ui/pixel_check_screen.dart';

void main() {
  testWidgets('a debug build opens on the pixel check screen', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    expect(find.byType(PixelCheckScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app name comes from the copy files', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PixelCheckScreen));
    expect(AppLocalizations.of(context).appName, 'Tomo');
    expect(tester.widget<Title>(find.byType(Title)).title, 'Tomo');
  });
}
