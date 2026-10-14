// The smallest PNG writer and reader the icon generator needs: 8-bit RGB or
// RGBA, no filters, no interlacing. Plain Dart with no packages; `dart:io` does the
// compression.

import 'dart:io';
import 'dart:typed_data';

/// A picture in memory, one `0xAARRGGBB` per pixel, row by row.
final class Picture {
  Picture(this.width, this.height) : pixels = Uint32List(width * height);

  final int width;
  final int height;
  final Uint32List pixels;

  void fill(int argb) => pixels.fillRange(0, pixels.length, argb);

  /// Fills the rectangle from ([left], [top]) up to but not including
  /// ([right], [bottom]).
  void fillRect(int left, int top, int right, int bottom, int argb) {
    for (var y = top; y < bottom; y++) {
      pixels.fillRange(y * width + left, y * width + right, argb);
    }
  }
}

/// Encodes [picture] as a PNG file. A picture with no see-through pixel is
/// written without an alpha channel, which the App Store asks of an app icon.
Uint8List encodePng(Picture picture) {
  final opaque = picture.pixels.every((argb) => argb >> 24 == 0xFF);
  final channels = opaque ? 3 : 4;
  final raw = BytesBuilder(copy: false);
  for (var y = 0; y < picture.height; y++) {
    final row = Uint8List(1 + picture.width * channels); // filter 0: none
    for (var x = 0; x < picture.width; x++) {
      final argb = picture.pixels[y * picture.width + x];
      final at = 1 + x * channels;
      row[at] = argb >> 16 & 0xFF;
      row[at + 1] = argb >> 8 & 0xFF;
      row[at + 2] = argb & 0xFF;
      if (!opaque) row[at + 3] = argb >> 24 & 0xFF;
    }
    raw.add(row);
  }

  final header = ByteData(13)
    ..setUint32(0, picture.width)
    ..setUint32(4, picture.height)
    ..setUint8(8, 8) // bits per channel
    ..setUint8(9, opaque ? 2 : 6); // colour type: RGB or RGBA
  // Compression, filter and interlace methods are all 0.

  return (BytesBuilder(copy: false)
        ..add(_signature)
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibEncoder(level: 9).convert(raw.takeBytes())))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

/// Decodes a PNG that [encodePng] wrote, or one in the same narrow shape.
/// Throws [FormatException] for anything else.
Picture decodePng(List<int> bytes) {
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  for (var i = 0; i < _signature.length; i++) {
    if (bytes[i] != _signature[i]) throw const FormatException('Not a PNG');
  }

  int? width, height, channels;
  final compressed = BytesBuilder(copy: false);
  var at = _signature.length;
  while (at < bytes.length) {
    final length = data.getUint32(at);
    final type = String.fromCharCodes(bytes, at + 4, at + 8);
    final body = at + 8;
    switch (type) {
      case 'IHDR':
        width = data.getUint32(body);
        height = data.getUint32(body + 4);
        channels = switch (bytes.sublist(body + 8, body + 13).join(',')) {
          '8,2,0,0,0' => 3,
          '8,6,0,0,0' => 4,
          _ => throw const FormatException('Only 8-bit RGB or RGBA'),
        };
      case 'IDAT':
        compressed.add(bytes.sublist(body, body + length));
    }
    at = body + length + 4; // past the CRC
  }
  if (width == null || height == null || channels == null) {
    throw const FormatException('No IHDR');
  }

  final raw = ZLibDecoder().convert(compressed.takeBytes());
  final picture = Picture(width, height);
  final stride = 1 + width * channels;
  for (var y = 0; y < height; y++) {
    if (raw[y * stride] != 0) throw const FormatException('Filtered row');
    for (var x = 0; x < width; x++) {
      final i = y * stride + 1 + x * channels;
      final alpha = channels == 4 ? raw[i + 3] : 0xFF;
      picture.pixels[y * width + x] =
          alpha << 24 | raw[i] << 16 | raw[i + 1] << 8 | raw[i + 2];
    }
  }
  return picture;
}

const _signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

Uint8List _chunk(String type, List<int> body) {
  final typeAndBody = [...type.codeUnits, ...body];
  final out = ByteData(12 + body.length)..setUint32(0, body.length);
  final bytes = out.buffer.asUint8List()..setAll(4, typeAndBody);
  out.setUint32(8 + body.length, _crc32(typeAndBody));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
