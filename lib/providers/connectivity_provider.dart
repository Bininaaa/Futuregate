import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isConnected => _isConnected;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  Future<void> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
