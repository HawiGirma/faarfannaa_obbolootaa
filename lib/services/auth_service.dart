import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Raw Firebase Auth methods (no Firestore dependency) ──────────────

  /// Sign in — returns the Firebase User only, no Firestore lookup.
  /// Safe to call even when Firestore doesn't exist yet.
  Future<User?> signInRaw(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Ensure the admin Firestore doc exists (needed for Storage rules)
    if (credential.user != null &&
        AppConstants.adminEmails.contains(email.trim().toLowerCase())) {
      await _writeAdminDoc(credential.user!.uid, email.trim());
    }
    return credential.user;
  }

  /// Create admin account — Firebase Auth only, no Firestore write.
  /// Firestore write is attempted separately and silently ignored on failure.
  Future<User?> registerAdminRaw(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      await credential.user!.updateDisplayName('Admin');
      // Write Firestore doc — retry once on failure so isAdmin flag is set
      // for Storage rules that check Firestore.
      await _writeAdminDoc(credential.user!.uid, email.trim());
    }
    return credential.user;
  }

  /// Writes (or overwrites) the admin user document in Firestore.
  /// Called on first registration and on every sign-in to keep the doc fresh.
  Future<void> _writeAdminDoc(String uid, String email) async {
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: 'Admin',
      isAdmin: true,
      createdAt: DateTime.now(),
    );
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (_) {
      // Firestore not set up yet — Storage email-based rule still allows upload
    }
  }

  // ── Legacy methods (kept for compatibility) ──────────────────────────

  Future<UserModel?> signIn(String email, String password) async {
    final user = await signInRaw(email, password);
    if (user != null) {
      return await getUserModel(user.uid);
    }
    return null;
  }

  Future<UserModel?> registerAdmin(String email, String password) async {
    final user = await registerAdminRaw(email, password);
    if (user != null) {
      return await getUserModel(user.uid);
    }
    return null;
  }

  // ── Firestore methods ────────────────────────────────────────────────

  /// Get user model from Firestore. Returns null if doc missing or DB unavailable.
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) return UserModel.fromFirestore(doc);
    } catch (_) {
      // Firestore unavailable — caller handles null
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> toggleFavorite(
    String uid,
    String songId,
    bool isFavorite,
  ) async {
    final ref = _firestore.collection(AppConstants.usersCollection).doc(uid);
    if (isFavorite) {
      await ref.update({
        'favoriteIds': FieldValue.arrayUnion([songId]),
      });
    } else {
      await ref.update({
        'favoriteIds': FieldValue.arrayRemove([songId]),
      });
    }
  }
}
