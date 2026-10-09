import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/models/reflection.dart';

/// The user's reflections, newest first (design S15).
final reflectionsProvider = StreamProvider<List<Reflection>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('users/$uid/reflections')
      .orderBy('localDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Reflection.fromMap(d.data())).toList());
});
