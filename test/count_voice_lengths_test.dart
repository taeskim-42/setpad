import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/count_voice_lengths.dart';
import 'package:setpad/workout_timing.dart';

/// The length an MP4 file declares: moov/trak/mdia/mdhd duration / timescale.
int mdhdMs(String path) {
  final b = ByteData.sublistView(File(path).readAsBytesSync());
  int find(List<String> names, int i, int end) {
    while (i + 8 <= end) {
      final size = b.getUint32(i);
      final kind = String.fromCharCodes(b.buffer.asUint8List(i + 4, 4));
      if (kind == names.first) {
        return names.length == 1 ? i : find(names.sublist(1), i + 8, i + size);
      }
      i += size;
    }
    throw StateError('$path: no ${names.first}');
  }

  final i = find(['moov', 'trak', 'mdia', 'mdhd'], 0, b.lengthInBytes);
  final (scale, length) = b.getUint8(i + 8) == 1
      ? (b.getUint32(i + 28), b.getUint64(i + 32))
      : (b.getUint32(i + 20), b.getUint32(i + 24));
  return (length * 1000 / scale).ceil();
}

void main() {
  test('세는 말 길이 표는 녹음 파일과 같다 (tool/make_count_voices.py --lengths)', () {
    for (final sex in ['m', 'w']) {
      expect(countVoiceMs[sex], hasLength(maxSpokenCount));
      for (var n = 1; n <= maxSpokenCount; n++) {
        expect(
          countVoiceMs[sex]![n - 1],
          closeTo(mdhdMs(countVoice(sex, n)), 2),
          reason: countVoice(sex, n),
        );
      }
    }
  });

  test('재생 길이 표는 녹음 파일의 iTunSMPB 유효 프레임과 같고, 파일 길이보다 짧다', () {
    final smpb = RegExp(r'iTunSMPB[\s\S]{0,40}?data[\s\S]{8}([ 0-9A-Fa-f]+)');
    for (final sex in ['m', 'w']) {
      expect(countVoicePlayMs[sex], hasLength(maxSpokenCount));
      for (var n = 1; n <= maxSpokenCount; n++) {
        final path = countVoice(sex, n);
        final text = latin1.decode(File(path).readAsBytesSync());
        final valid = int.parse(
          smpb.firstMatch(text)!.group(1)!.trim().split(' ')[3],
          radix: 16,
        );
        final ms = countVoicePlayMs[sex]![n - 1];
        expect(ms, (valid * 1000 / 44100).ceil(), reason: path);
        expect(ms, lessThan(countVoiceMs[sex]![n - 1]), reason: path);
      }
    }
  });

  test('구간 음성 길이 표도 녹음 파일과 같다', () {
    for (final sex in ['m', 'w']) {
      final files = {
        for (final f in Directory('assets/voice/en/$sex').listSync())
          if (f.path.endsWith('.m4a'))
            f.uri.pathSegments.last.replaceAll('.m4a', ''): f.path,
      };
      expect(phraseVoiceMs[sex]!.keys.toSet(), files.keys.toSet());
      for (final MapEntry(:key, :value) in files.entries) {
        expect(
          phraseVoiceMs[sex]![key],
          closeTo(mdhdMs(value), 2),
          reason: value,
        );
        expect(phraseVoice(sex, key), value);
      }
    }
  });
}
