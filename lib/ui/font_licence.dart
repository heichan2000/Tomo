import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the bundled font's licence lives (spec §9.2).
const arkPixelLicence = 'assets/fonts/ArkPixel-OFL.txt';

/// Registers Ark Pixel's licence, so it shows among the app's licences. The
/// OFL asks that every copy of the font carry it.
void registerFontLicence() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Ark Pixel Font',
    ], await rootBundle.loadString(arkPixelLicence));
  });
}
