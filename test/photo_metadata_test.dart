import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/record_ai.dart';

List<int> segment(int marker, List<int> body) => [
  0xFF,
  marker,
  (body.length + 2) >> 8,
  (body.length + 2) & 0xFF,
  ...body,
];

void main() {
  test('촬영 정보(Exif·XMP·IPTC·주석)는 떼고, 이미지 데이터는 그대로 둔다', () {
    final jfif = segment(0xE0, ascii.encode('JFIF\u0000'));
    final exif = segment(
      0xE1,
      ascii.encode('Exif\u0000\u0000GPSLatitude 37.5'),
    );
    final iptc = segment(0xED, ascii.encode('Photoshop 3.0'));
    final comment = segment(0xFE, ascii.encode('taken at home'));
    final table = segment(0xDB, List.filled(65, 1));
    final scan = [0xFF, 0xDA, 0x00, 0x04, 0x01, 0x02, 0x10, 0x20, 0xFF, 0xD9];
    final photo = Uint8List.fromList([
      0xFF,
      0xD8,
      ...jfif,
      ...exif,
      ...iptc,
      ...comment,
      ...table,
      ...scan,
    ]);
    final clean = withoutPhotoMetadata(photo);
    expect(clean, [0xFF, 0xD8, ...jfif, ...table, ...scan]);
    expect(latin1.decode(clean).contains('GPS'), isFalse);
  });

  test('JPEG 가 아니거나 깨졌으면 받은 그대로 — 끼니 기록을 막지 않는다', () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    expect(identical(withoutPhotoMetadata(png), png), isTrue);
    final broken = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0xFF, 0xFF, 1]);
    expect(identical(withoutPhotoMetadata(broken), broken), isTrue);
  });
}
