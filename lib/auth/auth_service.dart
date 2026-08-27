class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteAccount();

  Future<void> signOut();
}
