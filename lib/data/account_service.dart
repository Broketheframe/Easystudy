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

  Future<GlobalTicketStats> fetchGlobalTicketStats({
    required String currentUserId,
  }) async {
    final snapshot = await _firestore.collection(_usersCollection).get();

    final Map<int, int> completedByTicket = <int, int>{};
    final List<int> completedTicketsPerUser = <int>[];
    int usersCount = 0;
    int totalCompletedTickets = 0;
    int totalPerfectTickets = 0;

    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();
      final config = data['config'];
      if (config is! Map<String, dynamic>) continue;

      usersCount++;

      final ticketList = config['ticketsProgress'];
      if (ticketList is! List) {
        completedTicketsPerUser.add(0);
        continue;
      }

      final Set<int> completedTicketsForUser = <int>{};
      final Set<int> perfectTicketsForUser = <int>{};

      for (final raw in ticketList) {
        if (raw is! String) continue;

        final parsed = _parseTicketProgress(raw);
        if (parsed == null) continue;
        if (!parsed.isChemistry || !parsed.isCompleted) continue;

        completedTicketsForUser.add(parsed.ticketNumber);
        if (parsed.isPerfect) {
          perfectTicketsForUser.add(parsed.ticketNumber);
        }
      }

      for (final ticketNumber in completedTicketsForUser) {
        completedByTicket.update(
          ticketNumber,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      completedTicketsPerUser.add(completedTicketsForUser.length);
      totalCompletedTickets += completedTicketsForUser.length;
      totalPerfectTickets += perfectTicketsForUser.length;
    }

    return GlobalTicketStats(
      usersCount: usersCount,
      totalCompletedTickets: totalCompletedTickets,
      totalPerfectTickets: totalPerfectTickets,
      completedTicketsPerUser: completedTicketsPerUser,
      completedByTicket: completedByTicket,
    );
  }

  _ParsedTicketProgress? _parseTicketProgress(String serialized) {
    final parts = serialized.split('|');
    if (parts.length < 5) return null;

    final subjectIndex = int.tryParse(parts[0]);
    final ticketNumber = int.tryParse(parts[1]);
    final isCompleted = parts[3] == 'true';

    if (subjectIndex == null || ticketNumber == null) return null;

    bool isPerfect = false;
    final answersRaw = parts[4];
    if (answersRaw.isNotEmpty) {
      final answers = answersRaw.split(',');
      if (answers.isNotEmpty) {
        isPerfect = true;
        for (final answer in answers) {
          final kv = answer.split(':');
          if (kv.length != 2) {
            isPerfect = false;
            break;
          }
          if (kv[1] != '1') {
            isPerfect = false;
            break;
          }
        }
      }
    }

    return _ParsedTicketProgress(
      ticketNumber: ticketNumber,
      isCompleted: isCompleted,
      isChemistry: subjectIndex == Subject.chemistry.index,
      isPerfect: isCompleted && isPerfect,
    );
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

class GlobalTicketStats {
  const GlobalTicketStats({
    required this.usersCount,
    required this.totalCompletedTickets,
    required this.totalPerfectTickets,
    required this.completedTicketsPerUser,
    required this.completedByTicket,
  });

  final int usersCount;
  final int totalCompletedTickets;
  final int totalPerfectTickets;
  final List<int> completedTicketsPerUser;
  final Map<int, int> completedByTicket;

  double get averageCompletedTickets =>
      usersCount == 0 ? 0 : totalCompletedTickets / usersCount;
}

class _ParsedTicketProgress {
  const _ParsedTicketProgress({
    required this.ticketNumber,
    required this.isCompleted,
    required this.isChemistry,
    required this.isPerfect,
  });

  final int ticketNumber;
  final bool isCompleted;
  final bool isChemistry;
  final bool isPerfect;
}
