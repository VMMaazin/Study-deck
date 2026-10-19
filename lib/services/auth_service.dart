import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_deck/models/admin_user_model.dart';

/// Exception thrown when authentication or administrative authorization fails.
class AdminAuthException implements Exception {
  AdminAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Service managing authentication and verifying administrative authorization.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Verifies if a given UID has an active admin record in Firestore `users/{uid}`.
  Future<AdminUserModel?> checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      final adminUser = AdminUserModel.fromFirestore(doc);
      return adminUser.isAdmin ? adminUser : null;
    } catch (e, st) {
      developer.log('Error verifying admin status for $uid', error: e, stackTrace: st);
      return null;
    }
  }

  /// Signs in an administrator using email and password,
  /// then immediately verifies their admin authorization in Firestore.
  /// If the account is not an authorized admin, the session is terminated.
  Future<AdminUserModel> signInAdmin({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw AdminAuthException('Email and password must not be empty.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AdminAuthException('Authentication failed. User session not found.');
      }

      // Verify administrative role in Firestore
      final adminProfile = await checkAdminStatus(user.uid);
      if (adminProfile == null) {
        // Revoke unauthorized session immediately
        await _auth.signOut();
        throw AdminAuthException(
          'Access Denied: This account is not registered as an authorized administrator.',
        );
      }

      return adminProfile;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw AdminAuthException('Invalid email or password.');
        case 'user-disabled':
          throw AdminAuthException('This administrator account has been disabled.');
        case 'too-many-requests':
          throw AdminAuthException('Too many failed attempts. Please try again later.');
        case 'network-request-failed':
          throw AdminAuthException('Network error. Check your internet connection.');
        default:
          throw AdminAuthException(e.message ?? 'Authentication error occurred.');
      }
    } catch (e) {
      if (e is AdminAuthException) rethrow;
      throw AdminAuthException('Unexpected error during sign in: $e');
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, st) {
      developer.log('Error signing out', error: e, stackTrace: st);
      rethrow;
    }
  }
}
