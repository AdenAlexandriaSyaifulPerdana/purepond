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
      _errorMessage = null;
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
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      // Error lain selain dari FirebaseAuth
      debugPrint('Login error: ${e.toString()}');
      _isLoading = false;
      // _errorMessage = 'Login gagal. Periksa koneksi internet Anda.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _errorMessage = null;
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
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  // Method yang lebih fleksibel untuk menangani berbagai versi kode error
  String _getErrorMessage(String code) {
    // Ubah kode menjadi huruf kecil dan ganti underscore menjadi dash
    // agar mudah dibandingkan
    String lowerCode = code.toLowerCase().replaceAll('_', '-');

    // Di Firebase Auth versi terbaru, user-not-found dan wrong-password
    // digantikan oleh invalid-credential. Kita tangani di sini.
    if (lowerCode.contains('invalid-credential')) {
      return 'Username atau password salah.';
    }
    if (lowerCode.contains('user-not-found')) {
      return 'Username tidak terdaftar';
    }
    if (lowerCode.contains('wrong-password')) {
      return 'Password salah';
    }
    if (lowerCode.contains('invalid-email')) {
      return 'Format username tidak valid';
    }
    if (lowerCode.contains('network-request-failed') ||
        lowerCode.contains('network-error')) {
      return 'Koneksi internet bermasalah';
    }
    if (lowerCode.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
    }
    if (lowerCode.contains('operation-not-allowed')) {
      return 'Login dengan email/password belum diaktifkan.';
    }
    // Jika kode error tidak dikenali, tampilkan kode asli agar bisa di-debug
    return 'Gagal login (kode: $code)';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
