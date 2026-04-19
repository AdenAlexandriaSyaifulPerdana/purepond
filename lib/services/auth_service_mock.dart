import 'package:flutter/material.dart';

class AuthServiceMock extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mock login - SELALU BERHASIL dengan email "test@test.com" dan password "123456"
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (email == "test@test.com" && password == "123456") {
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoggedIn = false;
      _isLoading = false;
      _errorMessage =
          "Email atau password salah\nGunakan: test@test.com / 123456";
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.length < 6) {
      _isLoading = false;
      _errorMessage = "Password minimal 6 karakter";
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
