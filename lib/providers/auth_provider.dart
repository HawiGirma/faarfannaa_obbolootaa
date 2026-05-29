import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    // Listen to Supabase auth state changes
    _authService.authStateChanges.listen((authState) async {
      final supaUser = authState.session?.user;

      if (supaUser != null) {
        // Try to load the full user profile from the users table
        try {
          _user = await _authService.getUserModel(supaUser.id);
        } catch (_) {
          _user = null;
        }

        // Fall back to a minimal UserModel from auth metadata
        _user ??= UserModel(
          uid: supaUser.id,
          email: supaUser.email ?? '',
          displayName: 'Admin',
          isAdmin:
              AppConstants.adminEmails.contains(supaUser.email?.toLowerCase()),
          createdAt: DateTime.now(),
        );

        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });

    // Reflect current session on startup
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _status = AuthStatus.authenticated;
    }
  }

  // ── Admin sign-in ─────────────────────────────────────────────────────

  /// UI sends username "foAdmin" + password "admin@fo".
  /// We map those to the real Supabase email and sign in.
  Future<bool> adminSignIn(String username, String password) async {
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
      final user = await _authService.signIn(
        AppConstants.adminEmail,
        AppConstants.adminPassword,
      );
      if (user != null) return true;

      _errorMessage = 'Sign in failed.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      // Account doesn't exist yet — create it on first run
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') ||
          msg.contains('not found') ||
          msg.contains('credentials') ||
          msg.contains('email not confirmed') ||
          e.statusCode == '400') {
        return await _createAndSignInAdmin();
      }
      _errorMessage = _mapAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _createAndSignInAdmin() async {
    try {
      // Try to register first
      await _authService.registerAdmin(
        AppConstants.adminEmail,
        AppConstants.adminPassword,
      );
      // After signUp, immediately try signIn
      // (works when email confirmation is disabled)
      final user = await _authService.signIn(
        AppConstants.adminEmail,
        AppConstants.adminPassword,
      );
      if (user != null) return true;

      _errorMessage =
          'Account created. Please disable email confirmation in Supabase Dashboard → Authentication → Providers → Email → turn OFF "Confirm email", then try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already')) {
        // Account exists but sign-in failed — likely email confirmation pending
        _errorMessage =
            'Account exists but email confirmation may be required. '
            'Go to Supabase Dashboard → Authentication → Providers → Email → '
            'turn OFF "Confirm email", then try again.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      _errorMessage = _mapAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not create admin account: $e';
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

  // ── Favorites ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String songId) async {
    if (_user == null) return;
    final isFav = _user!.favoriteIds.contains(songId);
    try {
      await _authService.toggleFavorite(_user!.uid, songId, !isFav);
    } catch (e) {
      debugPrint('AuthProvider.toggleFavorite: $e');
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

  bool isFavorite(String songId) =>
      _user?.favoriteIds.contains(songId) ?? false;

  // ── Error mapping ─────────────────────────────────────────────────────

  String _mapAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid') || m.contains('credentials')) {
      return 'Invalid admin credentials.';
    }
    if (m.contains('too many')) return 'Too many attempts. Try again later.';
    if (m.contains('network')) return 'Network error. Check your connection.';
    return 'Sign in failed: $message';
  }
}
