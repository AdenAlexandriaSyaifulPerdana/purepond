import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  String _usernameToEmail(String username) {
    return '${username.trim()}@gmail.com';
  }

  Future<bool> signIn(String username, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String email = _usernameToEmail(username);

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _errorMessage = null; // ✅ Clear error sebelum logout
    notifyListeners();
    await _auth.signOut();
  }

  Future<bool> resetPassword(String username) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String email = _usernameToEmail(username);
      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Username tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format username tidak valid';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      default:
        return 'Terjadi kesalahan';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
