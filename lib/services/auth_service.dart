import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../utils/phone_validator.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Current session ───────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isSignedIn => currentUser != null;

  // ── Sign in with email (for backward compatibility) ──────────────────

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

  // ── Sign in with phone number ─────────────────────────────────────────

  Future<User?> signInWithPhone(String phoneNumber, String password) async {
    // Convert phone to email format
    final email = PhoneValidator.phoneToEmail(phoneNumber);

    final response = await _client.auth.signInWithPassword(
      email: email,
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

  // ── Sign up with phone number ─────────────────────────────────────────

  Future<User?> signUpWithPhone({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    // Convert phone to email format for Supabase Auth
    final email = PhoneValidator.phoneToEmail(phoneNumber);

    // Sign up with Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': fullName,
        'phone_number': phoneNumber,
      },
    );

    final user = response.user;
    if (user != null) {
      // Create user profile with phone number
      await _upsertUserDoc(
        user,
        isAdmin: false,
        displayName: fullName,
        phoneNumber: phoneNumber,
      );
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

  Future<void> _upsertUserDoc(
    User user, {
    required bool isAdmin,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      final name = displayName ??
          user.userMetadata?['display_name'] as String? ??
          'User';

      final phone =
          phoneNumber ?? user.userMetadata?['phone_number'] as String?;

      await _client.from(AppConstants.usersTable).upsert({
        'id': user.id,
        'email': user.email,
        'display_name': name,
        'phone_number': phone,
        'is_admin': isAdmin,
        'favorite_ids': [],
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('AuthService._upsertUserDoc: $e');
    }
  }
}
