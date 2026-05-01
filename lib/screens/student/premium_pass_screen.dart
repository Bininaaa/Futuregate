import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/subscription_status_card.dart';
import 'payment_result_screen.dart';

class PremiumPassScreen extends StatefulWidget {
  const PremiumPassScreen({super.key});

  @override
  State<PremiumPassScreen> createState() => _PremiumPassScreenState();
}

class _PremiumPassScreenState extends State<PremiumPassScreen>
    with WidgetsBindingObserver {
  bool _waitingForReturn = false;
  String? _pendingCheckoutId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PremiumProvider>().loadConfig();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForReturn) {
      _waitingForReturn = false;
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    if (!mounted) return;
    final premium = context.read<PremiumProvider>();
    final navigator = Navigator.of(context);
    await premium.syncAfterReturn();

    if (!mounted) return;
    final sub = context.read<SubscriptionProvider>();
    if (sub.hasActivePremium) return;

    if (_pendingCheckoutId != null) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            checkoutId: _pendingCheckoutId!,
          ),
        ),
      );
    }
  }

  Future<void> _startCheckout() async {
    final premium = context.read<PremiumProvider>();
    final sub = context.read<SubscriptionProvider>();

    if (sub.hasActivePremium) {
      _showSnack(AppLocalizations.of(context)!.premiumAlreadyActiveMessage);
      return;
    }

    final ok = await premium.startCheckout();
    if (!mounted) return;

    if (!ok) {
      _showSnack(premium.checkoutError ?? 'Payment setup failed.');
      return;
    }

    final url = premium.checkoutUrl?.trim();
    if (url == null || url.isEmpty) {
      _showSnack(premium.checkoutError ?? 'Payment setup failed.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !_isHttpUrl(uri)) {
      _showSnack('Could not open payment page.');
      return;
    }

    _pendingCheckoutId = premium.checkoutId;
    _waitingForReturn = true;

    final launched = await _launchCheckout(uri);
    if (!launched) {
      _waitingForReturn = false;
      _showSnack('Could not open payment page.');
    }
  }

  bool _isHttpUrl(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'https' || scheme == 'http') && uri.host.isNotEmpty;
  }

  Future<bool> _launchCheckout(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Fall back below. Some Android browsers report poorly through intents.
    }

    try {
      return launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final premium = context.watch<PremiumProvider>();
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Row(
          children: [
            Text(
              l10n.premiumPassTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const PremiumBadge(size: PremiumBadgeSize.small),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            _HeroCard(colors: colors, l10n: l10n, config: premium),

            const SizedBox(height: 20),

            // Subscription status
            Text(
              l10n.premiumStatusSection,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SubscriptionStatusCard(
              subscription: sub.subscription,
              isLoading: sub.isLoading,
              onUpgrade: _startCheckout,
            ),

            const SizedBox(height: 24),

            // Features list
            Text(
              'What\'s included',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _FeaturesList(colors: colors, l10n: l10n),

            const SizedBox(height: 32),

            // CTA button (show only if not active)
            if (!sub.hasActivePremium)
              _CtaButton(
                colors: colors,
                l10n: l10n,
                premium: premium,
                onTap: _startCheckout,
              ),

            const SizedBox(height: 16),

            // Test mode notice
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.paymentTestModeNotice,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final PremiumProvider config;

  const _HeroCard({
    required this.colors,
    required this.l10n,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryDeep,
            colors.primary,
            colors.accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: colors.softShadow(0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.premiumPassTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumPassDescription,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sell_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${config.config.price} ${config.config.currency}  ·  ${l10n.premiumPassPriceLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;

  const _FeaturesList({required this.colors, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.bolt_rounded, l10n.premiumFeatureEarlyAccess),
      (Icons.trending_up_rounded, l10n.premiumFeaturePriority),
      (Icons.bookmark_rounded, l10n.premiumFeatureSaved),
      (Icons.workspace_premium_rounded, l10n.premiumFeatureBadge),
    ];

    return Column(
      children: features.map((f) {
        final (icon, label) = f;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.check_circle_rounded,
                  size: 16, color: colors.success),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final PremiumProvider premium;
  final VoidCallback onTap;

  const _CtaButton({
    required this.colors,
    required this.l10n,
    required this.premium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = premium.isCheckoutLoading;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.workspace_premium_rounded, size: 20),
        label: Text(
          isLoading
              ? l10n.paymentOpeningCheckoutMessage
              : l10n.premiumPassUpgradeButton,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
