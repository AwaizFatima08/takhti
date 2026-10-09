import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/config.dart';
import '../../app/providers.dart';

/// A sign-in problem in plain words (design 5.2: never show raw Firebase codes).
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when the user closes the Google account picker; not an error to show.
class AuthCancelled implements Exception {
  const AuthCancelled();
}

String authMessage(Object e) {
  if (e is AuthFailure) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'email-already-in-use' =>
        'That email is already registered — sign in instead (or use Continue with Google).',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        'Wrong email or password.',
      'invalid-email' => 'That email address does not look right.',
      'weak-password' => 'Choose a stronger password: at least 8 characters, a letter and a number.',
      'network-request-failed' => 'No internet connection — try again.',
      'too-many-requests' => 'Too many attempts. Wait a few minutes and try again.',
      'user-disabled' => 'This account has been disabled.',
      'account-exists-with-different-credential' =>
        'This email uses another sign-in method. Sign in with email and password.',
      'requires-recent-login' => 'Please confirm your sign-in again and retry.',
      'user-mismatch' => 'Please choose the same Google account you signed in with.',
      _ => 'Something went wrong. Please try again.',
    };
  }
  if (e is FirebaseException && e.code == 'unavailable') {
    return 'No internet connection — try again.';
  }
  return 'Something went wrong. Please try again.';
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
  }

  /// Creates the auth account, the `users/{uid}` doc, and sends the
  /// verification email (use is not blocked until verified — D4).
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await createUserDoc(user, name: name, provider: 'password');
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Not fatal: Profile offers "resend".
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
  }

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    // serverClientId comes from google-services.json (default_web_client_id).
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  Future<OAuthCredential> _googleCredential() async {
    await _initGoogle();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure('Google sign-in failed. Please try again.');
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthCancelled();
      }
      throw AuthFailure('Google sign-in failed (${e.code.name}). Please try again.');
    }
  }

  /// Signs in with Google. The router sends first-time users to the
  /// 18+ / terms screen because they have no `users/{uid}` doc yet.
  Future<void> signInWithGoogle() async {
    final credential = await _googleCredential();
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
  }

  Future<void> createUserDoc(User user, {required String name, required String provider}) async {
    String timeZone = 'UTC';
    try {
      timeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {}
    await _db.doc('users/${user.uid}').set({
      'displayName': name.trim(),
      'email': user.email,
      'authProvider': provider,
      'ageConfirmed18': true,
      'ageConfirmedAt': FieldValue.serverTimestamp(),
      'termsVersion': kTermsVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'timeZone': timeZone,
      'remindersEnabled': false,
      'currentStreak': 0,
      'longestStreak': 0,
      'lessonsCompleted': 0,
    });
  }

  /// Always succeeds from the user's point of view (design S4: does not
  /// reveal which emails are registered).
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw AuthFailure(authMessage(e));
    }
  }

  Future<void> resendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
  }

  bool get usesGoogle =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// Re-authentication before account deletion (design 5.2).
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (password != null) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      } else {
        await user.reauthenticateWithCredential(await _googleCredential());
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
  }

  Future<void> deleteAuthUser() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e));
    }
    await _signOutGoogle();
  }

  Future<void> signOut() async {
    await _signOutGoogle();
    await _auth.signOut();
  }

  Future<void> _signOutGoogle() async {
    try {
      await _initGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
