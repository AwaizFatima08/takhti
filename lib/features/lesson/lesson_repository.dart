import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/models/lesson.dart';

/// Published lessons from Firestore (server first, then the offline cache),
/// falling back to the copy bundled in assets/lessons.json.
final lessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final db = ref.watch(firestoreProvider);
  try {
    final snap = await db
        .collection('lessons')
        .where('published', isEqualTo: true)
        .orderBy('order')
        .get()
        .timeout(const Duration(seconds: 8));
    if (snap.docs.isNotEmpty) {
      return snap.docs.map((d) => Lesson.fromMap(d.id, d.data())).toList();
    }
  } catch (_) {
    try {
      final cached = await db
          .collection('lessons')
          .where('published', isEqualTo: true)
          .orderBy('order')
          .get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        return cached.docs.map((d) => Lesson.fromMap(d.id, d.data())).toList();
      }
    } catch (_) {}
  }
  return bundledLessons();
});

Future<List<Lesson>> bundledLessons() async {
  final raw = jsonDecode(await rootBundle.loadString('assets/lessons.json')) as Map;
  return (raw['lessons'] as List)
      .map((m) => Map<String, dynamic>.from(m as Map))
      .where((m) => m['published'] == true)
      .map((m) => Lesson.fromMap(m['id'] as String, m))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

final lessonByIdProvider = Provider.family<Lesson?, String>((ref, id) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  for (final l in lessons) {
    if (l.id == id) return l;
  }
  return null;
});
