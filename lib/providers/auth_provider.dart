import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/badge_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<AppBadge> _newBadges = [];

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

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null) {
        try {
          _currentUser = await _authService
              .getUserProfile(firebaseUser.uid)
              .timeout(const Duration(seconds: 10));
        } on TimeoutException {
          _currentUser = _buildFallbackUser(firebaseUser);
        } catch (error) {
          if (_isMissingUserProfile(error)) {
            await _authService.signOut();
          } else {
            _currentUser = _buildFallbackUser(firebaseUser);
          }
        }
      }
    } catch (_) {
      // Firebase may not be ready yet.
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _isMissingUserProfile(Object error) {
    return error.toString().contains('User not found');
  }

  AppUser _buildFallbackUser(User firebaseUser) {
    final email = firebaseUser.email ?? '';
    final fallbackName = firebaseUser.displayName?.trim();

    return AppUser(
      uid: firebaseUser.uid,
      email: email,
      displayName: (fallbackName != null && fallbackName.isNotEmpty)
          ? fallbackName
          : (email.contains('@') ? email.split('@').first : 'User'),
      photoURL: firebaseUser.photoURL ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

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
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _getFirebaseErrorMessage(error.code);
      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _getFirebaseErrorMessage(error.code);
      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle();
      await _checkBadges();
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _getFirebaseErrorMessage(error.code);
      return false;
    } on PlatformException catch (error) {
      _error = _getGoogleSignInPlatformMessage(error);
      return false;
    } catch (error) {
      _error = _getGoogleSignInFallbackMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _getFirebaseErrorMessage(error.code);
      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _newBadges = [];
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      _currentUser = await _authService.getUserProfile(_currentUser!.uid);
      await _checkBadges();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _checkBadges() async {
    if (_currentUser == null) return;

    final awarded = await _badgeService.checkAndAwardBadges(_currentUser!);
    if (awarded.isNotEmpty) {
      _newBadges = awarded;
      _currentUser = await _authService.getUserProfile(_currentUser!.uid);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullaniliyor / Email already in use';
      case 'invalid-email':
        return 'Gecersiz e-posta / Invalid email';
      case 'weak-password':
        return 'Sifre cok zayif / Password too weak';
      case 'operation-not-allowed':
        return 'Bu giris yontemi Firebase Authentication tarafinda kapali. Firebase Console > Authentication > Sign-in method icinden etkinlestirmen gerekiyor.';
      case 'user-not-found':
        return 'Kullanici bulunamadi / User not found';
      case 'wrong-password':
        return 'Yanlis sifre / Wrong password';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-posta veya sifre hatali / Invalid email or password';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farkli bir giris yontemiyle kayitli. Once mevcut yontemle giris yapip sonra Google hesabini baglaman gerekiyor.';
      case 'user-disabled':
        return 'Bu hesap devre disi / This account is disabled';
      case 'network-request-failed':
        return 'Ag baglantisi hatasi / Network request failed';
      case 'too-many-requests':
        return 'Cok fazla deneme. Lutfen bekleyin / Too many attempts';
      case 'app-not-authorized':
        return 'Bu Android buildi Firebase/Google girisi icin yetkili degil. SHA-1 ve SHA-256 degerlerini Firebase Android uygulamasina ekleyip google-services.json dosyasini yenilemelisin.';
      default:
        return 'Bir hata olustu / An error occurred ($code)';
    }
  }

  String _getGoogleSignInPlatformMessage(PlatformException error) {
    final rawMessage = [
      error.code,
      error.message ?? '',
      '${error.details ?? ''}',
    ].join(' ').toLowerCase();

    if (rawMessage.contains('apiexception: 10')) {
      return 'Google girisi bu Android buildi icin yapilandirilmamis. Firebase Android uygulamasina SHA-1/SHA-256 ekleyip google-services.json dosyasini yeniden indirmelisin.';
    }

    if (rawMessage.contains('app-not-authorized')) {
      return 'Bu Android buildi Google girisi icin yetkili degil. Firebase Android uygulamasina SHA-1/SHA-256 ekleyip google-services.json dosyasini yeniden indirmelisin.';
    }

    if (rawMessage.contains('canceled') || rawMessage.contains('cancelled')) {
      return 'Google girisi iptal edildi / Google sign-in cancelled';
    }

    return 'Google girisinde hata olustu / Google sign-in failed';
  }

  String _getGoogleSignInFallbackMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('apiexception: 10')) {
      return 'Google girisi bu Android buildi icin yapilandirilmamis. Firebase Android uygulamasina SHA-1/SHA-256 ekleyip google-services.json dosyasini yeniden indirmelisin.';
    }

    if (message.contains('app-not-authorized')) {
      return 'Bu Android buildi Google girisi icin yetkili degil. Firebase Android uygulamasina SHA-1/SHA-256 ekleyip google-services.json dosyasini yeniden indirmelisin.';
    }

    if (message.contains('canceled') || message.contains('cancelled')) {
      return 'Google girisi iptal edildi / Google sign-in cancelled';
    }

    return 'Google girisinde hata olustu / Google sign-in failed';
  }
}
