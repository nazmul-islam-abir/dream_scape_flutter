import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isResending = false;
  bool _isVerified = false;
  int _attempts = 0;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  Future<void> _startVerificationCheck() async {
    _isPolling = true;

    // Check every 3 seconds for 1 minute (20 attempts)
    for (int i = 0; i < 20 && _isPolling; i++) {
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted || !_isPolling) return;

      // Refresh user session
      final user = await _authService.refreshUser();
      if (user != null && user.confirmedAt != null) {
        if (mounted) {
          setState(() {
            _isVerified = true;
            _isPolling = false;
          });

          _showSnackBar('✅ Email verified! Redirecting...', Colors.green);

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
        return;
      }

      // Update status
      if (mounted) {
        setState(() {
          _attempts = i + 1;
        });
      }
    }

    // After timeout, stop polling
    if (mounted) {
      setState(() {
        _isPolling = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.resendVerificationEmail(widget.email);

      if (mounted) {
        _showSnackBar(
          '✅ Verification email resent! Check your inbox.',
          Colors.green,
        );

        // Reset and restart verification check
        setState(() {
          _attempts = 0;
          _isPolling = true;
        });
        _startVerificationCheck();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ ${e.toString().replaceFirst('Exception: ', '')}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isVerified
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                ),
                child: Icon(
                  _isVerified
                      ? Icons.check_circle_rounded
                      : Icons.email_rounded,
                  size: 64,
                  color: _isVerified
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isVerified
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isVerified) ...[
                Text(
                  'We sent a verification email to:',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your inbox and click the verification link.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              // Status Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isVerified
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isVerified
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isVerified
                          ? Icons.verified_rounded
                          : _isPolling
                          ? Icons.timer_rounded
                          : Icons.hourglass_empty_rounded,
                      color: _isVerified ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isVerified
                            ? 'Your account is now active!'
                            : _isPolling
                            ? '⏳ Waiting for verification... (${_attempts * 3}s)'
                            : '📧 Click the link in your email to verify',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _isVerified
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_isVerified) ...[
                // Resend Button
                ElevatedButton.icon(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.email_outlined),
                  label: Text(
                    _isResending ? 'Resending...' : 'Resend Verification Email',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Help Tips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade800,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tips:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Check your spam/junk folder\n'
                        '• Wait a minute for the email to arrive\n'
                        '• Click the link in the email to verify',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Back to Login Button
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
