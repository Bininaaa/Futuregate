import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color _primaryOrange = Color(0xFFFF8C00);
  static const Color _darkPurple = Color(0xFF2D1B4E);

  bool _checking = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final verified = await authProvider.reloadAndCheckVerification();

    if (!mounted) return;

    if (verified) {
      // Reload user profile and let AuthWrapper handle navigation
      await authProvider.loadCurrentUser();
    } else {
      setState(() {
        _message =
            'Email not verified yet. Please check your inbox and spam folder.';
        _isError = true;
      });
    }

    setState(() => _checking = false);
  }

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.sendEmailVerification();

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _message = error;
        _isError = true;
      });
    } else {
      setState(() {
        _message = 'Verification email sent! Check your inbox.';
        _isError = false;
      });
    }

    setState(() => _resending = false);
  }

  Future<void> _backToLogin() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0FF), Color(0xFFFFF5EB), Color(0xFFFFF0F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 24),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryOrange, Color(0xFFFFAA33)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryOrange.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.mark_email_unread_outlined,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Verify your email',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _darkPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a verification link to your email address. '
            'Please check your inbox and click the link to activate your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Feedback message
          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: _isError
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isError
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // I verified my email button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _checking ? null : _checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: _primaryOrange.withValues(alpha: 0.4),
                disabledBackgroundColor: _primaryOrange.withValues(alpha: 0.5),
              ),
              child: _checking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'I verified my email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Resend email button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _resending ? null : _resendEmail,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: _resending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.grey.shade500,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Resend email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Back to login
          TextButton(
            onPressed: _backToLogin,
            child: Text(
              'Back to login',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
