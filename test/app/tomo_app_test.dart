import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/ui/kit_gallery_screen.dart';

void main() {
  testWidgets('a debug build opens on the kit gallery', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    expect(find.byType(KitGalleryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app name comes from the copy files', (tester) async {
    await tester.pumpWidget(const TomoApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(KitGalleryScreen));
    expect(AppLocalizations.of(context).appName, 'Tomo');
    expect(tester.widget<Title>(find.byType(Title)).title, 'Tomo');
  });
}
