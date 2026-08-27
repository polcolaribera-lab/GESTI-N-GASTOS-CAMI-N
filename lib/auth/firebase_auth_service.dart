import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;

  @override
  Stream<AuthUser?> get authStateChanges => _firebaseAuth
      .authStateChanges()
      .map((user) => user == null ? null : _toAuthUser(user));

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _toAuthUser(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await _firebaseAuth.signInWithPopup(provider);
        return;
      }

      await _initializeGoogleSignIn();
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google no ha devuelto una credencial válida. Inténtalo de nuevo.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      throw AuthFailure(_messageForGoogle(error));
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        return;
      }
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.setLanguageCode('es');
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthFailure('No hay ninguna cuenta iniciada.');
    }
    final signedInWithGoogle = user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );

    try {
      await user.delete();
      if (!kIsWeb && signedInWithGoogle) {
        try {
          await _initializeGoogleSignIn();
          await _googleSignIn.signOut();
        } catch (_) {
          // La cuenta de Firebase ya se ha eliminado. La limpieza local de
          // Google no debe impedir que se borren los datos del dispositivo.
        }
      }
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    final signedInWithGoogle = _firebaseAuth.currentUser?.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    await _firebaseAuth.signOut();
    if (!kIsWeb && signedInWithGoogle == true) {
      try {
        await _initializeGoogleSignIn();
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase ya ha cerrado la sesión. La limpieza local de Google es
        // secundaria y no debe impedir que el usuario salga de Ruta Clara.
      }
    }
  }

  static Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  static AuthUser _toAuthUser(User user) {
    return AuthUser(uid: user.uid, email: user.email ?? 'Cuenta de Ruta Clara');
  }

  static String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'El correo electrónico no tiene un formato válido.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'El correo o la contraseña no son correctos.',
      'email-already-in-use' => 'Ya existe una cuenta con este correo.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'user-disabled' => 'Esta cuenta está desactivada.',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos y vuelve a probar.',
      'network-request-failed' =>
        'No se pudo conectar. Revisa tu conexión a internet.',
      'operation-not-allowed' =>
        'El acceso con correo todavía no está habilitado.',
      'requires-recent-login' =>
        'Por seguridad, cierra la sesión, vuelve a entrar y repite la eliminación.',
      'account-exists-with-different-credential' =>
        'Ya existe una cuenta con este correo. Entra con el método que usaste anteriormente.',
      'popup-blocked' =>
        'El navegador ha bloqueado la ventana de Google. Permite las ventanas emergentes y vuelve a probar.',
      _ => 'No se pudo completar la operación. Inténtalo de nuevo.',
    };
  }

  static String _messageForGoogle(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'No se pudo configurar el acceso con Google en este dispositivo.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'No se pudo abrir el selector de cuentas de Google.',
      GoogleSignInExceptionCode.interrupted =>
        'El acceso con Google se ha interrumpido. Vuelve a intentarlo.',
      _ => 'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
    };
  }
}
