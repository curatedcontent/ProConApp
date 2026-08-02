import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  Future<User?> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError(
          'Google sign-in is currently only available in the web app.');
    }
    final provider = GoogleAuthProvider();
    final credential = await _auth.signInWithPopup(provider);
    return credential.user;
  }

  Future<void> signOut() => _auth.signOut();
}
