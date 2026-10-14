import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takhti_grow/app/config.dart';
import 'package:takhti_grow/features/auth/validators.dart';
import 'package:takhti_grow/shared/models/lesson.dart';

void main() {
  test('password rule: 8+ chars, a letter and a number', () {
    expect(validateNewPassword('short1'), isNotNull);
    expect(validateNewPassword('allletters'), isNotNull);
    expect(validateNewPassword('12345678'), isNotNull);
    expect(validateNewPassword('grow2026'), isNull);
  });

  test('name 2–40 characters', () {
    expect(validateName('A'), isNotNull);
    expect(validateName('Homi'), isNull);
    expect(validateName('x' * 41), isNotNull);
  });

  test('email shape', () {
    expect(validateEmail('a@b.co'), isNull);
    expect(validateEmail('nope'), isNotNull);
  });

  test('kAppVersion and kAppBuild match pubspec version', () {
    final m = RegExp(r'^version:\s*([\d.]+)\+(\d+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!;
    expect(m.group(1), kAppVersion);
    expect(int.parse(m.group(2)!), kAppBuild);
  });

  test('bundled lessons are valid (3 bullets, 3 quiz questions, clip range)', () {
    final raw = jsonDecode(File('assets/lessons.json').readAsStringSync()) as Map;
    final lessons = (raw['lessons'] as List)
        .map((m) => Lesson.fromMap(m['id'] as String, Map<String, dynamic>.from(m as Map)))
        .toList();
    expect(lessons.length, greaterThanOrEqualTo(4));
    expect(lessons.map((l) => l.id).toSet(), hasLength(lessons.length), reason: 'ids are unique');
    expect(lessons.map((l) => l.order).toList()..sort(), [for (var i = 1; i <= lessons.length; i++) i],
        reason: 'orders run 1..N with no gaps');
    for (final l in lessons) {
      expect(l.keyIdea, hasLength(3), reason: l.id);
      expect(l.quiz, hasLength(3), reason: l.id);
      expect(l.youtubeId, hasLength(11), reason: l.id);
      expect(l.clipEndSec, greaterThan(l.clipStartSec), reason: l.id);
      for (final q in l.quiz) {
        expect(q.options, hasLength(3));
        expect(q.correctIndex, inInclusiveRange(0, 2));
      }
    }
  });
}
