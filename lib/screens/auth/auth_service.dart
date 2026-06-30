import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // SIGN UP - Fixed with proper verification
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // IMPORTANT: Sign up with email confirmation enabled
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': username,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // Check if user was created
      if (response.user != null) {
        print('✅ User created: ${response.user!.email}');
        print('📧 Confirmation email should be sent to: $email');
        print('🔑 User ID: ${response.user!.id}');

        // Return the response - user needs to verify email
        return response;
      } else {
        throw Exception('Sign up failed - no user created');
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  // SIGN IN - Works with email confirmation
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (response.user != null && response.user!.confirmedAt == null) {
        print('⚠️ Email not verified for: $email');
        // Still return the response, let UI handle the verification check
      }

      return response;
    } catch (e) {
      print('❌ Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // RESEND VERIFICATION - Fixed
  Future<void> resendVerificationEmail(String email) async {
    try {
      // Use the correct resend method
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      print('✅ Verification email resent to: $email');
    } catch (e) {
      print('❌ Resend error: $e');
      throw Exception('Failed to resend verification email: $e');
    }
  }

  // REFRESH USER SESSION
  Future<User?> refreshUser() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.user;
    } catch (e) {
      print('⚠️ Refresh error: $e');
      return _supabase.auth.currentUser;
    }
  }

  // CHECK IF USER IS VERIFIED
  bool isUserVerified() {
    final user = _supabase.auth.currentUser;
    return user != null && user.confirmedAt != null;
  }

  // GET CURRENT USER
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      print('✅ Password reset email sent to: $email');
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // UPDATE PROFILE
  Future<void> updateProfile({String? username, String? fullName}) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      final Map<String, dynamic> data = {};
      if (username != null) data['username'] = username;
      if (fullName != null) data['full_name'] = fullName;

      await _supabase.auth.updateUser(UserAttributes(data: data));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // UPDATE PASSWORD
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // GET USER PROFILE
  Map<String, dynamic>? getUserProfile() {
    final user = getCurrentUser();
    if (user == null) return null;

    return {
      'email': user.email,
      'username': user.userMetadata?['username'] ?? 'User',
      'full_name': user.userMetadata?['full_name'] ?? 'User',
      'created_at': user.createdAt,
      'confirmed_at': user.confirmedAt,
      'last_sign_in_at': user.lastSignInAt,
    };
  }

  // Check email verification status
  Future<bool> checkEmailVerificationStatus() async {
    final user = getCurrentUser();
    if (user == null) return false;

    // Refresh user to get latest status
    final refreshedUser = await refreshUser();
    if (refreshedUser != null) {
      return refreshedUser.confirmedAt != null;
    }

    return user.confirmedAt != null;
  }
}
