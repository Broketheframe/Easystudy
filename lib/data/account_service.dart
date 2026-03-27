import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'game_state.dart';

class AccountService {
  AccountService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  Future<bool> isSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.isAnonymous) return false;
    if (user.email != null && !user.emailVerified) return false;
    return true;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AuthResult> register({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after registration',
      );
    }

    await user.sendEmailVerification();
    await _saveConfig(user.uid, state.toConfigMap());
    await _auth.signOut();

    return AuthResult(token: user.uid, configApplied: false);
  }

  Future<AuthResult> login({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after login',
      );
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      await _auth.signOut();
      throw const EmailNotVerifiedException();
    }

    bool applied = false;
    final config = await _loadConfig(refreshedUser.uid);
    if (config != null) {
      await state.applyConfigMap(config);
      applied = true;
    } else {
      await _saveConfig(refreshedUser.uid, state.toConfigMap());
    }

    return AuthResult(token: user.uid, configApplied: applied);
  }

  Future<void> syncUp(GameState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRequiredException();
    }
    await _saveConfig(user.uid, state.toConfigMap());
  }

  Future<bool> syncDown(GameState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRequiredException();
    }
    final config = await _loadConfig(user.uid);
    if (config == null) return false;
    await state.applyConfigMap(config);
    return true;
  }

  Future<Map<String, dynamic>?> _loadConfig(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final config = data['config'];
    return config is Map<String, dynamic> ? config : null;
  }

  Future<void> _saveConfig(String uid, Map<String, dynamic> config) async {
    await _firestore.collection(_usersCollection).doc(uid).set({
      'config': config,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 1,
    }, SetOptions(merge: true));
  }
}

class AuthResult {
  AuthResult({required this.token, required this.configApplied});

  final String token;
  final bool configApplied;
}

class AuthRequiredException implements Exception {
  const AuthRequiredException();
}

class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();
}
