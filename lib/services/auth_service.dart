import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Login dengan email dan password
  Future<User?> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      print('Email dan password tidak boleh kosong.');
      return null;
    }

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Login gagal [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('Terjadi error tak terduga saat login: $e');
      return null;
    }
  }

  /// Registrasi akun baru
  Future<User?> register(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      print('Email dan password tidak boleh kosong.');
      return null;
    }

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Registrasi gagal [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('Terjadi error tak terduga saat registrasi: $e');
      return null;
    }
  }

  /// Logout user saat ini
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Gagal logout: $e');
    }
  }

  /// Ambil user yang sedang login
  User? get currentUser => _auth.currentUser;
}
