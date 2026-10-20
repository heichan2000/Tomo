import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// The phone's own share sheet (spec §8.1, §13): Settings → About →
/// *Share diagnostics* hands it the diagnostic log as a `.txt`, and the user
/// picks where it goes. Tomo sends nothing itself.
abstract interface class ShareSheet {
  /// Offers [text] as a plain-text file called [fileName].
  Future<void> shareTextFile({required String fileName, required String text});
}

/// [ShareSheet] on a real phone, through `share_plus`.
final class PhoneShareSheet implements ShareSheet {
  const PhoneShareSheet();

  @override
  Future<void> shareTextFile({
    required String fileName,
    required String text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(text),
            mimeType: 'text/plain',
            name: fileName,
          ),
        ],
        // The file's name is lost on the way unless given again here.
        fileNameOverrides: [fileName],
      ),
    );
  }
}
