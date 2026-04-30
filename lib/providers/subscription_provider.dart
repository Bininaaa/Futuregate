import 'dart:async';

import 'package:flutter/material.dart';

import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();

  SubscriptionModel? _subscription;
  bool _isLoading = false;
  StreamSubscription<SubscriptionModel?>? _sub;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get hasActivePremium => _subscription?.isActive ?? false;

  void listenToSubscription(String uid) {
    _sub?.cancel();
    if (uid.isEmpty) {
      _subscription = null;
      notifyListeners();
      return;
    }
    _sub = _service.subscriptionStream(uid).listen((sub) {
      _subscription = sub;
      notifyListeners();
    });
  }

  Future<void> refresh(String uid) async {
    if (uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    _subscription = await _service.getSubscription(uid);
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _subscription = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
