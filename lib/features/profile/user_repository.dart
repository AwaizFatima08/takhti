import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/providers.dart';
import '../../shared/models/user_profile.dart';

/// `users/{uid}`: null when signed out or when the doc does not exist yet.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .doc('users/$uid')
      .snapshots()
      .map((d) => d.exists ? UserProfile.fromDoc(d) : null);
});

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository(ref.watch(firestoreProvider)));

class UserRepository {
  UserRepository(this._db);
  final FirebaseFirestore _db;

  Future<void> updateName(String uid, String name) =>
      _db.doc('users/$uid').update({'displayName': name.trim()});

  Future<void> saveReminders(
    String uid, {
    required String lessonTime,
    required String reflectionTime,
    required bool enabled,
  }) =>
      _db.doc('users/$uid').update({
        'reminderLessonTime': lessonTime,
        'reminderReflectionTime': reflectionTime,
        'remindersEnabled': enabled,
      });

  Future<void> sendFeedback(String uid, int rating, String comment) =>
      _db.collection('feedback').add({
        'uid': uid,
        'rating': rating,
        'comment': comment.trim(),
        'appBuild': kAppBuild,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Deletes everything the user owns (design 8.5, D6), before the auth user.
  Future<void> deleteAllUserData(String uid) async {
    final refs = <DocumentReference>[];
    for (final sub in ['reflections', 'progress']) {
      final snap = await _db.collection('users/$uid/$sub').get();
      refs.addAll(snap.docs.map((d) => d.reference));
    }
    final feedback = await _db.collection('feedback').where('uid', isEqualTo: uid).get();
    refs.addAll(feedback.docs.map((d) => d.reference));
    refs.add(_db.doc('users/$uid'));
    // Batches hold up to 500 writes; the pilot has < 20 docs per user.
    for (var i = 0; i < refs.length; i += 450) {
      final batch = _db.batch();
      for (final r in refs.skip(i).take(450)) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }
}
