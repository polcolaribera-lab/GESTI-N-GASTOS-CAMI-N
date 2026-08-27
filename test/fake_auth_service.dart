import 'dart:async';

import 'package:ruta_clara/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService.signedIn()
    : _currentUser = const AuthUser(
        uid: 'test-user',
        email: 'transportista@rutaclara.es',
      );

  FakeAuthService.signedOut() : _currentUser = null;

  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _changes.stream;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(uid: 'registered-user', email: email.trim());
    _changes.add(_currentUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _changes.add(null);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _currentUser = AuthUser(uid: 'signed-in-user', email: email.trim());
    _changes.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = const AuthUser(
      uid: 'google-user',
      email: 'transportista@gmail.com',
    );
    _changes.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _changes.add(null);
  }
}
