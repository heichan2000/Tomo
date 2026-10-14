import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/font_licence.dart';

void main() {
  test('Ark Pixel\'s licence is registered, OFL text and all', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicence();

    final entries = await LicenseRegistry.licenses.toList();
    final ark = entries.where((e) => e.packages.contains('Ark Pixel Font'));

    expect(ark, hasLength(1));
    final text = ark.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(text, contains('TakWolf'));
  });
}
