import 'dart:async';

import 'package:flutter/material.dart';

import '../models/premium_config_model.dart';
import '../models/subscription_model.dart';
import '../services/chargily_payment_service.dart';
import '../services/premium_service.dart';

enum PremiumCheckoutState { idle, loading, success, failed }

class PremiumProvider extends ChangeNotifier {
  final PremiumService _premiumService = PremiumService();
  final ChargilyPaymentService _chargilyService = ChargilyPaymentService();

  PremiumConfigModel _config = PremiumConfigModel.defaults;
  PremiumCheckoutState _checkoutState = PremiumCheckoutState.idle;
  String? _checkoutUrl;
  String? _checkoutId;
  String? _checkoutError;
  StreamSubscription<PremiumConfigModel>? _configSub;

  PremiumConfigModel get config => _config;
  PremiumCheckoutState get checkoutState => _checkoutState;
  String? get checkoutUrl => _checkoutUrl;
  String? get checkoutId => _checkoutId;
  String? get checkoutError => _checkoutError;
  bool get isCheckoutLoading => _checkoutState == PremiumCheckoutState.loading;

  void startConfigStream() {
    _configSub?.cancel();
    _configSub = _premiumService.configStream().listen((cfg) {
      _config = cfg;
      notifyListeners();
    });
  }

  Future<void> loadConfig() async {
    _config = await _premiumService.getConfig();
    notifyListeners();
  }

  Future<bool> startCheckout() async {
    _checkoutState = PremiumCheckoutState.loading;
    _checkoutUrl = null;
    _checkoutId = null;
    _checkoutError = null;
    notifyListeners();

    final result = await _chargilyService.createCheckout(config: _config);

    if (result.ok) {
      _checkoutUrl = result.checkoutUrl;
      _checkoutId = result.checkoutId;
      _checkoutState = PremiumCheckoutState.success;
      notifyListeners();
      return true;
    }

    _checkoutError = result.errorMessage ?? 'Payment setup failed.';
    _checkoutState = PremiumCheckoutState.failed;
    notifyListeners();
    return false;
  }

  void resetCheckout() {
    _checkoutState = PremiumCheckoutState.idle;
    _checkoutUrl = null;
    _checkoutId = null;
    _checkoutError = null;
    notifyListeners();
  }

  Future<void> syncAfterReturn() async {
    await _chargilyService.syncSubscription();
  }

  // Delegation helpers

  bool canApplyNow({
    required SubscriptionModel? sub,
    required bool premiumEarlyAccess,
    required DateTime? publicVisibleAt,
  }) {
    return _premiumService.canApplyNow(
      sub: sub,
      premiumEarlyAccess: premiumEarlyAccess,
      publicVisibleAt: publicVisibleAt,
    );
  }

  bool isEarlyAccessLockedForUser({
    required SubscriptionModel? sub,
    required bool premiumEarlyAccess,
    required DateTime? publicVisibleAt,
  }) {
    return _premiumService.isEarlyAccessLockedForUser(
      sub: sub,
      premiumEarlyAccess: premiumEarlyAccess,
      publicVisibleAt: publicVisibleAt,
    );
  }

  Duration getRemainingEarlyAccessTime(DateTime? publicVisibleAt) =>
      _premiumService.getRemainingEarlyAccessTime(publicVisibleAt);

  bool canSaveMoreItems({
    required SubscriptionModel? sub,
    required int currentCount,
  }) {
    return _premiumService.canSaveMoreItems(
      sub: sub,
      currentCount: currentCount,
      config: _config,
    );
  }

  bool shouldShowPremiumBadge(SubscriptionModel? sub) =>
      _premiumService.shouldShowPremiumBadge(sub);

  bool shouldPrioritizeApplication(SubscriptionModel? sub) =>
      _premiumService.shouldPrioritizeApplication(sub);

  Future<void> approveEarlyAccess({
    required String opportunityId,
    required String adminUid,
    int? delayHours,
  }) {
    return _premiumService.approveEarlyAccess(
      opportunityId: opportunityId,
      adminUid: adminUid,
      delayHours: delayHours ?? _config.earlyAccessDefaultDelayHours,
    );
  }

  Future<void> rejectEarlyAccess({
    required String opportunityId,
    required String adminUid,
    required String reason,
  }) {
    return _premiumService.rejectEarlyAccess(
      opportunityId: opportunityId,
      adminUid: adminUid,
      reason: reason,
    );
  }

  Future<void> makePostNormal(String opportunityId) =>
      _premiumService.makePostNormal(opportunityId);

  Future<void> requestEarlyAccess(String opportunityId) =>
      _premiumService.requestEarlyAccess(opportunityId);

  @override
  void dispose() {
    _configSub?.cancel();
    super.dispose();
  }
}
