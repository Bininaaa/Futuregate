import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';

class PaymentResultScreen extends StatefulWidget {
  final String checkoutId;

  const PaymentResultScreen({super.key, required this.checkoutId});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  _State _state = _State.checking;
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 10;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        if (mounted) setState(() => _state = _State.pending);
        return;
      }
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    _pollCount++;
    await context.read<PremiumProvider>().syncAfterReturn();
    if (!mounted) return;

    final subProvider = context.read<SubscriptionProvider>();
    final uid =
        subProvider.subscription?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    await subProvider.refresh(uid ?? '');
    if (!mounted) return;

    final sub = subProvider.subscription;
    if (sub?.isActive == true) {
      _pollTimer?.cancel();
      setState(() => _state = _State.success);
    } else if (sub?.isFailed == true) {
      _pollTimer?.cancel();
      setState(() => _state = _State.failed);
    }
  }

  Future<void> _syncAndRetry() async {
    setState(() => _state = _State.checking);
    _pollCount = 0;
    await context.read<PremiumProvider>().syncAfterReturn();
    if (!mounted) return;
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        automaticallyImplyLeading: _state != _State.checking,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: switch (_state) {
            _State.checking => _CheckingView(colors: colors, l10n: l10n),
            _State.success => _SuccessView(colors: colors, l10n: l10n),
            _State.pending => _PendingView(
              colors: colors,
              l10n: l10n,
              onCheck: _syncAndRetry,
            ),
            _State.failed => _FailedView(
              colors: colors,
              l10n: l10n,
              onRetry: () => Navigator.of(context).pop(),
            ),
          },
        ),
      ),
    );
  }
}

enum _State { checking, success, pending, failed }

class _CheckingView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  const _CheckingView({required this.colors, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.paymentPendingTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.paymentPendingMessage,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  const _SuccessView({required this.colors, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.accent, colors.accent.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.paymentSuccessTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colors.accent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.paymentSuccessMessage,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.closeLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback onCheck;
  const _PendingView({
    required this.colors,
    required this.l10n,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_bottom_rounded, size: 64, color: colors.warning),
        const SizedBox(height: 20),
        Text(
          l10n.premiumPassPendingTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.premiumPassPendingMessage,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: onCheck,
          icon: Icon(Icons.refresh_rounded, color: colors.primary),
          label: Text(
            l10n.paymentCheckStatusButton,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: Text(
            l10n.closeLabel,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback onRetry;
  const _FailedView({
    required this.colors,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: colors.danger),
        const SizedBox(height: 20),
        Text(
          l10n.paymentFailedTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.paymentFailedMessage,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.paymentRetryButton),
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
