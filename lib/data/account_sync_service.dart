import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'account_service.dart';
import 'game_state.dart';

class AccountSyncService with WidgetsBindingObserver {
  AccountSyncService({
    required GameState state,
    AccountService? accountService,
    FirebaseAuth? auth,
  }) : _state = state,
       _accountService = accountService ?? AccountService(),
       _auth = auth ?? FirebaseAuth.instance;

  static const Duration _debounceDelay = Duration(seconds: 2);
  static const Duration _periodicSyncInterval = Duration(minutes: 5);

  final GameState _state;
  final AccountService _accountService;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  bool _dirty = false;
  bool _isSyncing = false;
  bool _isApplyingRemote = false;
  User? _lastAuthUser;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _state.addListener(_onLocalStateChanged);

    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(_onAuthStateChanged(user));
    });

    _periodicTimer = Timer.periodic(_periodicSyncInterval, (_) {
      unawaited(flush());
    });

    unawaited(_onAuthStateChanged(_auth.currentUser));
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_onLocalStateChanged);
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    await _authSubscription?.cancel();
    await flush();
  }

  void _onLocalStateChanged() {
    if (_isApplyingRemote) return;

    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      unawaited(flush());
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    final previousUid = _lastAuthUser?.uid;
    final currentUid = user?.uid;
    _lastAuthUser = user;

    if (!_canSync(user)) return;

    final isNewSession = previousUid != currentUid;
    if (isNewSession) {
      await _syncDownOrCreateRemote();
      return;
    }

    await flush();
  }

  bool _canSync(User? user) {
    return user != null &&
        !user.isAnonymous &&
        (user.email == null || user.emailVerified);
  }

  Future<void> _syncDownOrCreateRemote() async {
    if (_isSyncing) return;

    final user = _auth.currentUser;
    if (!_canSync(user)) return;

    _isSyncing = true;
    try {
      _isApplyingRemote = true;
      final hasRemote = await _accountService.syncDown(_state);
      _isApplyingRemote = false;

      if (!hasRemote) {
        await _accountService.syncUp(_state);
      }

      _dirty = false;
    } catch (_) {
      _isApplyingRemote = false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> flush() async {
    if (_isSyncing || !_dirty) return;

    final user = _auth.currentUser;
    if (!_canSync(user)) return;

    _isSyncing = true;
    try {
      await _accountService.syncUp(_state);
      _dirty = false;
    } catch (_) {
      _dirty = true;
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(flush());
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }
}
