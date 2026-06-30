// ============== firebase_auth_service.dart ==============
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);
        await user.reload();

        // Send email verification
        await user.sendEmailVerification();

        // Don't sign out - let the user stay logged in
        // The auth wrapper will handle the verification check
      }

      return user;
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email first. Check your inbox!');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to resend: ${e.toString()}');
    }
  }

  bool isUserVerified() {
    final User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  String? getUserName() {
    return _auth.currentUser?.displayName;
  }

  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  Future<void> updateProfile({String? username, String? photoURL}) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        if (username != null) {
          await user.updateDisplayName(username);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}