import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    
    if (email != null && password != null) {
      await signIn(email, password);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Kullanıcı bulunamadı';
        case 'wrong-password':
          return 'Hatalı şifre';
        case 'email-already-in-use':
          return 'Bu email zaten kullanımda';
        case 'weak-password':
          return 'Şifre çok zayıf';
        case 'invalid-email':
          return 'Geçersiz email adresi';
        default:
          return 'Bir hata oluştu: ${error.code}';
      }
    }
    return error.toString();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await AuthRepository.signUp(
        email: email,
        password: password,
        username: username,
      );
    } catch (e) {
      _error = _getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await AuthRepository.signIn(email, password);
      
      if (rememberMe && _currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }
    } catch (e) {
      _error = _getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthRepository.signOut();
    _currentUser = null;
    
    // Kayıtlı bilgileri temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    
    notifyListeners();
  }
}