import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Thin data layer around Supabase Auth.
/// Keeps all Supabase-specific calls in one place so the rest
/// of the app only talks to this repository, not the SDK directly.
class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Currently logged-in user, or null if no session exists.
  User? get currentUser => _client.auth.currentUser;

  /// True if a session exists (used for "remember login" auto-navigation).
  bool get isLoggedIn => _client.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
      emailRedirectTo: 'io.smartmeds.app://email-verified',
    );
    return response;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.smartmeds.app://reset-password',
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  bool get isEmailVerified {
    final user = currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
