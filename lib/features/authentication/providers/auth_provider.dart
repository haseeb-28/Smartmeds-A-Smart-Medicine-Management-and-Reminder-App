import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

/// Repository singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Live stream of Supabase auth state — used for "remember login"
/// so the app can auto-route to Dashboard or Login on startup.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Whether a session currently exists (drives splash/auto-login routing).
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => ref.read(authRepositoryProvider).isLoggedIn,
  );
});

enum AuthStatus { idle, loading, success, error }

class AuthFormState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthFormState({
    this.status = AuthStatus.idle,
    this.errorMessage,
  });

  AuthFormState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Handles login, register, and forgot-password submissions,
/// exposing a single status enum the UI can react to.
class AuthController extends StateNotifier<AuthFormState> {
  AuthController(this._repository) : super(const AuthFormState());

  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.register(name: name, email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> sendResetLink(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> resendVerification(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.resendVerificationEmail(email);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthFormState();
  }

  void resetStatus() {
    state = const AuthFormState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
