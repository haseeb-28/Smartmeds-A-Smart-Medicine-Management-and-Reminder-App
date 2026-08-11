import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 4s to check if the user verified their email
    // in another tab/app, so we can auto-advance without a manual refresh.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final repo = ref.read(authRepositoryProvider);
      if (repo.isEmailVerified) {
        _pollTimer?.cancel();
        _goToLogin();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    await ref
        .read(authControllerProvider.notifier)
        .resendVerification(widget.email);

    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
      if (next.status == AuthStatus.success && previous?.status != next.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.forward_to_inbox,
                  size: 72, color: Colors.blueGrey),
              const SizedBox(height: 20),
              Text(
                'Almost there!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This screen will update automatically once verified.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              AuthButton(
                label: _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend Email',
                onPressed: _resendCooldown > 0 ? null : _resendEmail,
                isLoading: authState.status == AuthStatus.loading,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goToLogin,
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
