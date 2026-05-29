import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Current session ───────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isSignedIn => currentUser != null;

  // ── Sign in ───────────────────────────────────────────────────────────

  Future<User?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _upsertUserDoc(user, isAdmin: _isAdminEmail(user.email));
    }
    return user;
  }

  // ── Register (first-time admin setup) ────────────────────────────────

  Future<User?> registerAdmin(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _upsertUserDoc(user, isAdmin: true);
    }
    return user;
  }

  // ── Sign out ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── User profile ──────────────────────────────────────────────────────

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final row = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row != null) return UserModel.fromMap(row);
    } catch (e) {
      debugPrint('AuthService.getUserModel: $e');
    }
    return null;
  }

  // ── Favorites ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite(
    String uid,
    String songId,
    bool isFavorite,
  ) async {
    // Read current list, mutate, write back
    final row = await _client
        .from(AppConstants.usersTable)
        .select('favorite_ids')
        .eq('id', uid)
        .maybeSingle();

    final current = (row?['favorite_ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    if (isFavorite) {
      if (!current.contains(songId)) current.add(songId);
    } else {
      current.remove(songId);
    }

    await _client
        .from(AppConstants.usersTable)
        .update({'favorite_ids': current}).eq('id', uid);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  bool _isAdminEmail(String? email) =>
      AppConstants.adminEmails.contains(email?.toLowerCase());

  Future<void> _upsertUserDoc(User user, {required bool isAdmin}) async {
    try {
      await _client.from(AppConstants.usersTable).upsert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'] ?? 'Admin',
        'is_admin': isAdmin,
        'favorite_ids': [],
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('AuthService._upsertUserDoc: $e');
    }
  }
}
