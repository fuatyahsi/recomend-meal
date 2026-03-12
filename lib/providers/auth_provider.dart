import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../models/badge_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<AppBadge> _newBadges = []; // Newly earned badges to show

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _currentUser?.isPremium ?? false;
  List<AppBadge> get newBadges => _newBadges;

  void clearNewBadges() {
    _newBadges = [];
    notifyListeners();
  }

  /// Initialize: check if user already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null) {
        try {
          _currentUser = await _authService.getUserProfile(firebaseUser.uid)
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          // Profile not found or timeout, sign out
          await _authService.signOut();
        }
      }
    } catch (_) {
      // Firebase not ready or other error
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Sign Up ---
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Sign In ---
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      await _checkBadges();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Google Sign In ---
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle();
      await _checkBadges();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Password Reset ---
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _newBadges = [];
    notifyListeners();
  }

  // --- Refresh User ---
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    try {
      _currentUser = await _authService.getUserProfile(_currentUser!.uid);
      await _checkBadges();
      notifyListeners();
    } catch (_) {}
  }

  // --- Badge Check ---
  Future<void> _checkBadges() async {
    if (_currentUser == null) return;
    final awarded = await _badgeService.checkAndAwardBadges(_currentUser!);
    if (awarded.isNotEmpty) {
      _newBadges = awarded;
      // Refresh user to get updated badges list
      _currentUser = await _authService.getUserProfile(_currentUser!.uid);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanılıyor / Email already in use';
      case 'invalid-email':
        return 'Geçersiz e-posta / Invalid email';
      case 'weak-password':
        return 'Şifre çok zayıf / Password too weak';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı / User not found';
      case 'wrong-password':
        return 'Yanlış şifre / Wrong password';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin / Too many attempts';
      default:
        return 'Bir hata oluştu / An error occurred ($code)';
    }
  }
}
