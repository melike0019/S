import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;

  // Dışarıdan okunabilir, ama değiştirilemez
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  // --- BAŞLANGIÇTA OTURUM KONTROLÜ ---
  void _init() {
    _authService.authStateChanges.listen(
      (firebaseUser) async {
        if (firebaseUser != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

            if (doc.exists) {
              var model = UserModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              // Firestore'da displayName boşsa Firebase Auth'tan al
              if (model.displayName.isEmpty) {
                final fbName = firebaseUser.displayName ?? '';
                if (fbName.isNotEmpty) {
                  model = model.copyWith(displayName: fbName);
                }
              }
              _user = model;
            } else {
              // Firestore belgesi yoksa Firebase Auth verisinden kullanıcı oluştur
              _user = UserModel(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                displayName: firebaseUser.displayName ?? '',
                createdAt: DateTime.now(),
              );
            }
            _status = AuthStatus.authenticated;
          } catch (e) {
            // Okuma hatası olsa bile Firebase Auth'tan minimal kullanıcı oluştur
            _user ??= UserModel(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? '',
              createdAt: DateTime.now(),
            );
            _status = AuthStatus.authenticated;
          }
        } else {
          _status = AuthStatus.unauthenticated;
          _user = null;
        }
        notifyListeners();
      },
      onError: (e) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      },
    );
  }

  // --- KAYIT OL ---
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
  }) async {
    _errorMessage = null;

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        birthDate: birthDate,
      );

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- GİRİŞ YAP ---
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- GOOGLE İLE GİRİŞ ---
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) return false; // İptal edildi
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    _setLoading();
    try {
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- ŞİFRE SIFIRLA ---
  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- KULLANICI VERİSİNİ YENİLE (fotoğraf vb. güncelleme sonrası) ---
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .get();
      if (doc.exists) {
        _user = UserModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
        notifyListeners();
      }
    } catch (_) {}
  }

  // --- YARDIMCI METODLAR ---
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}