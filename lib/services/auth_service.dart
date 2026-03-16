import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Email/Password Auth ---
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    return _upsertUserProfile(
      credential.user!,
      displayNameOverride: displayName,
    );
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _upsertUserProfile(credential.user!);
  }

  // --- Google Sign-In ---
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return _upsertUserProfile(userCredential.user!);
  }

  // --- Password Reset ---
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore disconnect errors if there is no active Google session.
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- User Profile ---
  Future<AppUser> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User not found');
    return AppUser.fromFirestore(doc);
  }

  Future<AppUser> _upsertUserProfile(
    User user, {
    String? displayNameOverride,
  }) async {
    final users = _firestore.collection('users');
    final doc = await users.doc(user.uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }

    final email = user.email ?? '';
    final displayName = _resolveDisplayName(
      user: user,
      displayNameOverride: displayNameOverride,
    );

    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      photoURL: user.photoURL ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
    );

    await users.doc(user.uid).set(appUser.toFirestore(), SetOptions(merge: true));
    return appUser;
  }

  String _resolveDisplayName({
    required User user,
    String? displayNameOverride,
  }) {
    final preferred = displayNameOverride?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final firebaseName = user.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    final email = user.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());
  }

  Stream<AppUser?> userStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }
}
