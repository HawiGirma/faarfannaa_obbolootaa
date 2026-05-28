import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Try Firestore — but never crash if it's unavailable
        try {
          _user = await _authService.getUserModel(firebaseUser.uid);
        } catch (_) {
          _user = null;
        }

        // Fall back to a local UserModel built from Firebase Auth data
        _user ??= UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: 'Admin',
          isAdmin: AppConstants.adminEmails
              .contains(firebaseUser.email?.toLowerCase()),
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  /// Admin sign-in.
  /// UI sends username "foAdmin" + password "admin@fo".
  /// We map those to the real Firebase email and sign in.
  Future<bool> adminSignIn(String username, String password) async {
    // Step 1 — validate the simple display credentials
    if (username.trim() != AppConstants.adminUsername ||
        password != AppConstants.adminPassword) {
      _errorMessage = 'Invalid admin credentials.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 2 — sign in with the real Firebase email
      await _authService.signInRaw(
        AppConstants.adminFirebaseEmail,
        AppConstants.adminPassword,
      );
      // _init() listener will fire and set _user + _status automatically
      return true;
    } on FirebaseAuthException catch (e) {
      // Step 3 — account doesn't exist yet → create it
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        return await _createAndSignInAdmin();
      }
      _errorMessage = _getAuthError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _errorMessage = 'Sign in failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Creates the admin Firebase Auth account on first use, then signs in.
  Future<bool> _createAndSignInAdmin() async {
    try {
      await _authService.registerAdminRaw(
        AppConstants.adminFirebaseEmail,
        AppConstants.adminPassword,
      );
      // _init() listener fires automatically after account creation
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Race condition — account exists, just sign in
        try {
          await _authService.signInRaw(
            AppConstants.adminFirebaseEmail,
            AppConstants.adminPassword,
          );
          return true;
        } on Exception catch (inner) {
          _errorMessage = 'Sign in failed: ${inner.toString()}';
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        }
      }
      _errorMessage = _getAuthError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _errorMessage = 'Could not create admin account: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    if (_user == null) return;
    final isFav = _user!.favoriteIds.contains(songId);
    try {
      await _authService.toggleFavorite(_user!.uid, songId, !isFav);
    } catch (_) {
      // Firestore may not be set up yet — update local state only
    }
    final updatedFavs = List<String>.from(_user!.favoriteIds);
    if (isFav) {
      updatedFavs.remove(songId);
    } else {
      updatedFavs.add(songId);
    }
    _user = _user!.copyWith(favoriteIds: updatedFavs);
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _user?.favoriteIds.contains(songId) ?? false;
  }

  String _getAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Admin account not found.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid admin credentials.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      default:
        return 'Sign in failed ($code).';
    }
  }
}
